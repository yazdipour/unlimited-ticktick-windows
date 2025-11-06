namespace TTPatcher
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("TTPatcher - TickTick License Patcher");
            Console.WriteLine("=====================================");
            
            // Parse command line arguments
            var inputPath = GetInputPath(args);
            if (inputPath == null) return;

            // Generate output path
            var outputPath = GenerateOutputPath(inputPath);
            
            // Create patcher and run
            var patcher = new DnlibAssemblyPatcher();
            var success = patcher.PatchAssembly(inputPath, outputPath);
            
            if (success)
            {
                Console.WriteLine($"✅ Patching completed successfully!");
                Console.WriteLine($"📁 Patched file: {outputPath}");
            }
            else
            {
                Console.WriteLine("❌ Patching failed!");
            }
        }

        private static string? GetInputPath(string[] args)
        {
            string inputPath;
            
            // Check if path was provided as command line argument
            if (args.Length > 0)
            {
                inputPath = args[0].Trim('"'); // Remove quotes if present
                Console.WriteLine($"Using provided path: {inputPath}");
            }
            else
            {
                // Look for TickTick.exe in current directory
                inputPath = Path.Combine(Directory.GetCurrentDirectory(), "TickTick.exe");
                Console.WriteLine($"Looking for TickTick.exe in current directory: {inputPath}");
            }
            
            if (!File.Exists(inputPath))
            {
                if (args.Length > 0)
                {
                    Console.WriteLine("❌ File not found at the provided path!");
                }
                else
                {
                    Console.WriteLine("❌ TickTick.exe not found in the current directory!");
                    Console.WriteLine();
                    Console.WriteLine("Usage:");
                    Console.WriteLine("  TTPatcher.exe                           - Look for TickTick.exe in current directory");
                    Console.WriteLine("  TTPatcher.exe \"path\\to\\TickTick.exe\"   - Use specific path");
                }
                return null;
            }
            
            Console.WriteLine($"✅ Found TickTick.exe at: {inputPath}");
            return inputPath;
        }

        private static string GenerateOutputPath(string inputPath)
        {
            var directory = Path.GetDirectoryName(inputPath) ?? "";
            var fileName = Path.GetFileNameWithoutExtension(inputPath);
            var extension = Path.GetExtension(inputPath);
            
            return Path.Combine(directory, $"{fileName}_Patched{extension}");
        }
    }
}
