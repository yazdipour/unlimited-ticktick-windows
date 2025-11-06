namespace TTPatcher
{
    // Interface for different patching implementations
    public interface IAssemblyPatcher
    {
        bool PatchAssembly(string inputPath, string outputPath);
    }
}
