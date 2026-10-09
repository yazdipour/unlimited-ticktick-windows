# Unlimited TickTick - Windows

> [!TIP]
> You can also find a MacOS version of this patch in the [Unlimited TickTick - MacOS ](https://github.com/yazdipour/unlimited-ticktick-macos) repository.

> [!TIP]
> If you want to learn how you can do the same for Linux🐧/Electron version of the ticktick [follow instructions by the community.](https://github.com/yazdipour/unlimited-ticktick-windows/issues/12)

### How to use? 

- Upgrade or Install the original TickTick (Chinese Ticktick/dida365 will not work - personally never tried it).
- Close the app from System tray completely.
- Copy the exe file inside installed path (usually `C:\Program Files (x86)\TickTick`). Have a backup from the original exe file just in case.

> [!CAUTION]
> Want the new version or Just got the update notification? First update the app from the app itself, then replace the patched exe file with the new one. This way you can keep enjoying the pro features without losing them after each update.

### Download the patched executable for Windows:

You can also download the final patched executable from [the releases page.](https://github.com/yazdipour/cracked-ticktick-windows/releases)

---

### Cloud Build (GitHub Actions)

If you don't have a local .NET development environment set up, or just prefer to build the patched app in the cloud, you can use GitHub Actions to generate your own patched executable.

1. **Fork this repository** using the fork button on the top right.
2. Go to the **Actions** tab on your newly forked repository. If prompted, click the button to enable workflows.
3. On the left sidebar under "All workflows", click on **Build Patched TickTick**.
4. Click the **Run workflow** button on the right side.
5. Provide a direct URL to your original `TickTick.exe` file
    - **⚠️Installed exe from program file, not the installer**
    - **⚠️ You can upload it to [filebin.net](https://filebin.net), or any other hosting service that gives a direct download link (e.g. not going to work with Google Drive)**
    - **⚠️ You might need to rename the .exe part to .ANYTHING to upload it in those online services, the script will automatically rename it to exe.**
7. Click **Run workflow** and wait for the build to finish.
8. Go to the **Releases** section on the right side of your repository's main page. You will find a new **Draft release** containing your `TickTick_Patched.zip` file ready to download.
9. Download the ZIP, extract the `TickTick_Patched.exe` file, and replace your original `TickTick.exe` located in your TickTick installation folder (usually `C:\Program Files (x86)\TickTick`).

---

### Build a patched installer (GitHub Actions)

01. Open **Actions > Build Patched TickTick Installer > Run workflow**.
02. Enter the direct **HTTPS URL of the original Windows x64 installer EXE**, not the installed `TickTick.exe`. Use a trusted source.
03. Download `TickTick-Patched-Installer` from the workflow artifacts, or `TickTick Unlimited.exe` from the new draft release.

This separate workflow downloads the installer, extracts its payload without running setup, patches `TickTick.exe`, and builds a new installer. Before publishing, it extracts the result and checks every payload file against its SHA-256 hash. The existing executable-only workflow is unchanged.

#### Installer integration test

**Test Patched TickTick Installer** runs on pushes to every branch, on pull requests, and manually from Actions. It downloads the installer, runs the complete packaging pipeline, checks every repacked payload hash, and inspects the patched getters inside the final installer. It does not install or launch TickTick, and it does not create releases. Logs and the generated installer are uploaded as `installer-test-results` for 7 days.

01. Default test input: `https://download.ticktick.app/download/win64/tick_win_setup_release_x64_8215.exe`.
02. To change the URL for automatic runs without editing code, set repository variable **`TICKTICK_TEST_INSTALLER_URL`** under **Settings > Secrets and variables > Actions > Variables**. A manual run can override it with the optional `installer_url` input. Priority: manual input, repository variable, default in `scripts/Test-PatchedInstaller.ps1`. A broken download fails the test; there is no silent fallback.
03. To block PR merges, configure the target branch ruleset or branch protection to **require pull requests** and the **`Installer integration test`** status check. Run the workflow once if the check is not selectable yet. Enable **Require branches to be up to date before merging** to require a passing check against the latest target branch. Workflow triggers alone do not enforce merge restrictions; repository settings must be configured separately. Fork PRs may require workflow approval under the repository's Actions policy.

```powershell
# Full integration test using the default URL (or TICKTICK_TEST_INSTALLER_URL).
./scripts/Test-PatchedInstaller.ps1

# Override the input for one local test run.
./scripts/Test-PatchedInstaller.ps1 -InstallerUrl "https://example.com/ticktick-setup.exe"
```

#### Run locally (Windows, PowerShell 7 and .NET 8 SDK)

```powershell
# Use your downloaded installer; the original file is never modified.
./scripts/Build-PatchedInstaller.ps1 -InstallerPath ./tick_win_setup_release_x64_8215.exe

# Or download the installer from a direct URL.
./scripts/Build-PatchedInstaller.ps1 -InstallerUrl "https://example.com/ticktick-setup.exe"
```

Output: `artifacts/installer/TickTick Unlimited.exe`. For subsequent runs, pass a fresh `-OutputDirectory`; existing installers are not overwritten. Working files stay in that directory for inspection and can be removed manually afterward. Repository-root `tick_win_setup*.exe` files and `artifacts/` are ignored by Git.

Internet access is required even for local input: the script downloads checksum-pinned portable [Inno Unpacker](https://github.com/jrathlev/InnoUnpacker-Windows-GUI) and [Inno Setup 6.7.0](https://github.com/jrsoftware/issrc/releases/tag/is-6_7_0) tools. Neither tool is installed system-wide. The extractor supports Inno Setup through 6.7.3; unsupported formats or file-copy rules fail instead of producing a partial package. Duplicate file destinations are resolved in original installation order.

> [!IMPORTANT]
> This is a **new unsigned installer**, not the original signed setup. It targets Windows 10+ x64-compatible systems and installs per-user under `%LOCALAPPDATA%\Programs\TickTick Patched`, with its own uninstall entry and Start menu shortcut. Vendor setup code, protocol registration, startup tasks and prerequisite installation are not reproduced. Required app runtimes, including .NET Framework and WebView2, must already be available. It does not deliberately remove user data on uninstall, but the app still shares its normal data locations with an official installation. Close TickTick before installing or using this copy. App updates can replace the patch, and server-side restrictions remain.

---

### Features

- Calendar view
- Widgets
- Reminders
- Themes
- ⚠️ Unlimited Habits (Might not sync properly)
- ⚠️ **Some features might not work if it is restricted on server side**
## Patch with TTPatcher Script

### Using .NET (Direct)
```bash
# Build and run
dotnet run -- "D:\TickTick.exe"

# Or build then run
dotnet build
dotnet bin/Debug/net8.0/TTPatcher.dll "D:\TickTick.exe"
```

### Using Docker

#### Build
```bash
docker build -t ttpatcher .
```

#### Patch
```bash
docker run --rm -v "/path/to/directory:/data" ttpatcher "/data/TickTick.exe"
```

#### Examples

```bash
# Build image
docker build -t ttpatcher .

# Patch file (Windows)
# This should output to C:/Users/username/Desktop/TickTick_Patched.exe
docker run --rm -v "C:/Users/username/Desktop:/data" ttpatcher "/data/TickTick.exe"

# Patch file (WSL/Linux)
# This should output to /mnt/c/Users/username/Desktop/TickTick_Patched.exe
docker run --rm -v "/mnt/c/Users/username/Desktop:/data" ttpatcher "/data/TickTick.exe" 
```

### Learn how it was made

- Use dnSpy
- Update these:

<details>
<summary>Approach 1: UserModel Property Modification</summary>

```csharp
// in ticktick_WPF.Models.UserModel
proEndDate=>DateTime.MaxValue;
pro=>true;
```
</details>

<details>
<summary>Approach 2: LocalSettings and UserDao Modification</summary>

```csharp
// in ticktick_WPF.Resource.LocalSettings
public bool IsPro
{
  get
  {
    return this.SettingsModel.IsPro;
  }
  set
  {
    this.SettingsModel.IsPro = true; //force it to true
    this.OnPropertyChanged("IsPro");
  }
}
```
</details>

## Disclaimer

This repository is provided for informational and educational purposes only.
