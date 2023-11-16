# Premium TickTick Windows Client

All Premium features UNLOCKED.

[Download Here](https://github.com/yazdipour/cracked-ticktick-windows/releases)

## How to use? 

- Upgrade or Install the original TickTick (Chinese Ticktick/dida365 will not work).
- Close the app from System tray completely.
- Copy the exe file inside installed path (usually `C:\Program Files (x86)\TickTick`)
- Enjoy!

## How I made it

- Use dnSpy
- Update these:

Legacy way:

```
// in ticktick_WPF.Models.UserModel
proEndDate=>new DateTime?(new DateTime(2030, 12, 25));
pro=>true;
```

New way:

```c#
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

// ticktick_WPF.Dal.UserDao
//public static bool IsPro()
//{
//  return true; // force to true
//}
```
