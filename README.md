# Premium TickTick Windows Client

### For Ubuntu and probably Macos users:
> [!TIP]
> If you want to learn how you can do the same for Electron version of the ticktick [follow instructions by the community.](https://github.com/yazdipour/unlimited-ticktick-windows/issues/12)

### How to use? 

- Upgrade or Install the original TickTick (Chinese Ticktick/dida365 will not work - personally never tried it).
- Close the app from System tray completely.
- Copy the exe file inside installed path (usually `C:\Program Files (x86)\TickTick`). Have a backup from the original exe file just in case.

### Uploaded executable for Windows:

You can also download the final patched executable output from [Here](https://github.com/yazdipour/cracked-ticktick-windows/releases)

### Features

- Calendar view
- Widgets
- Reminders
- Themes
- ⚠️ Unlimited Habits (Might not sync properly)
- ⚠️ Some features might not work if it is restricted on server side

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
