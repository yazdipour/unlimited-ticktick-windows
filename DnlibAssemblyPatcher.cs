using dnlib.DotNet;
using dnlib.DotNet.Emit;

namespace TTPatcher
{
    // dnlib implementation of the patcher
    public class DnlibAssemblyPatcher : IAssemblyPatcher
    {
        public bool PatchAssembly(string inputPath, string outputPath)
        {
            try
            {
                Console.WriteLine("Loading assembly with dnlib...");
                
                // Load the assembly
                var module = ModuleDefMD.Load(inputPath);
                Console.WriteLine($"Module loaded: {module.Name}");

                // Find and patch the UserModel
                var patchSuccess = PatchUserModel(module);
                
                if (!patchSuccess)
                {
                    Console.WriteLine("Failed to patch UserModel properties.");
                    return false;
                }

                // Save the patched assembly
                Console.WriteLine($"Saving patched assembly to: {outputPath}");
                module.Write(outputPath);
                Console.WriteLine("Assembly saved successfully!");
                
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error during patching: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
                return false;
            }
        }

        private bool PatchUserModel(ModuleDef module)
        {
            Console.WriteLine("Searching for UserModel type...");
            
            // Find the UserModel type
            var userModelType = module.Types.FirstOrDefault(t => t.FullName == "ticktick_WPF.Models.UserModel");
            if (userModelType == null)
            {
                Console.WriteLine("UserModel type not found!");
                LogAvailableTypes(module);
                return false;
            }

            Console.WriteLine($"Found UserModel: {userModelType.FullName}");
            Console.WriteLine($"Properties in UserModel: {userModelType.Properties.Count}");

            // Patch both properties
            var proPatch = PatchProProperty(userModelType);
            var proEndDatePatch = PatchProEndDateProperty(userModelType);

            return proPatch && proEndDatePatch;
        }

        private bool PatchProProperty(TypeDef userModelType)
        {
            var proProperty = userModelType.Properties.FirstOrDefault(p => p.Name == "pro");
            if (proProperty == null)
            {
                Console.WriteLine("Property 'pro' not found in UserModel.");
                return false;
            }

            // Remove setter if it exists
            if (proProperty.SetMethod != null)
            {
                userModelType.Methods.Remove(proProperty.SetMethod);
                proProperty.SetMethod = null;
                Console.WriteLine("Removed 'pro' property setter.");
            }

            // Modify getter to return true
            if (proProperty.GetMethod != null)
            {
                var getter = proProperty.GetMethod;
                getter.Body = new CilBody();
                
                // Create IL instructions: load true, return
                getter.Body.Instructions.Add(OpCodes.Ldc_I4_1.ToInstruction()); // Load 1 (true)
                getter.Body.Instructions.Add(OpCodes.Ret.ToInstruction());       // Return

                Console.WriteLine("Patched 'pro' property to return true.");
                return true;
            }

            Console.WriteLine("Property 'pro' has no getter method.");
            return false;
        }

        private bool PatchProEndDateProperty(TypeDef userModelType)
        {
            var proEndDateProperty = userModelType.Properties.FirstOrDefault(p => p.Name == "proEndDate");
            if (proEndDateProperty == null)
            {
                Console.WriteLine("Property 'proEndDate' not found in UserModel.");
                return false;
            }

            Console.WriteLine($"proEndDate property type: {proEndDateProperty.PropertySig.RetType}");

            // Remove setter if it exists
            if (proEndDateProperty.SetMethod != null)
            {
                userModelType.Methods.Remove(proEndDateProperty.SetMethod);
                proEndDateProperty.SetMethod = null;
                Console.WriteLine("Removed 'proEndDate' property setter.");
            }

            // Modify getter to return DateTime.MaxValue with proper nullable conversion
            if (proEndDateProperty.GetMethod != null)
            {
                var getter = proEndDateProperty.GetMethod;
                getter.Body = new CilBody();
                
                var module = userModelType.Module;
                
                // Find DateTime type in the target assembly's references (not import from current runtime)
                var dateTimeTypeRef = new TypeRefUser(module, "System", "DateTime", module.CorLibTypes.AssemblyRef);
                
                // Create field reference for DateTime.MaxValue in the target assembly's context
                var maxValueFieldRef = new MemberRefUser(module, "MaxValue", 
                    new FieldSig(dateTimeTypeRef.ToTypeSig()), dateTimeTypeRef);
                
                // Create nullable DateTime constructor reference in the target assembly's context
                var nullableTypeRef = new TypeRefUser(module, "System", "Nullable`1", module.CorLibTypes.AssemblyRef);
                var nullableDateTimeType = new GenericInstSig(nullableTypeRef.ToTypeSig().ToClassOrValueTypeSig(), dateTimeTypeRef.ToTypeSig());
                var nullableCtorRef = new MemberRefUser(module, ".ctor", 
                    MethodSig.CreateInstance(module.CorLibTypes.Void, dateTimeTypeRef.ToTypeSig()), 
                    nullableDateTimeType.ToTypeDefOrRef());
                
                // Create IL instructions:
                // 1. Load DateTime.MaxValue
                getter.Body.Instructions.Add(OpCodes.Ldsfld.ToInstruction(maxValueFieldRef));
                // 2. Create new nullable DateTime with MaxValue
                getter.Body.Instructions.Add(OpCodes.Newobj.ToInstruction(nullableCtorRef));
                // 3. Return
                getter.Body.Instructions.Add(OpCodes.Ret.ToInstruction());

                Console.WriteLine("Patched 'proEndDate' property to return DateTime.MaxValue (using target assembly references).");
                return true;
            }

            Console.WriteLine("Property 'proEndDate' has no getter method.");
            return false;
        }

        private void LogAvailableTypes(ModuleDef module)
        {
            Console.WriteLine($"Total types in module: {module.Types.Count}");
            Console.WriteLine("Sample types (first 10):");
            
            foreach (var type in module.Types.Take(10))
            {
                Console.WriteLine($"  - {type.FullName}");
            }
            
            if (module.Types.Count > 10)
            {
                Console.WriteLine($"  ... and {module.Types.Count - 10} more types");
            }
        }
    }
}
