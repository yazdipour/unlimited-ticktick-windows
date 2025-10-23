# Premium TickTick Windows Client

## For Ubuntu and probably Macos:
> [!TIP]
> If you want to learn how you can do the same for Electron version of the ticktick [follow instructions by the community.](https://github.com/yazdipour/unlimited-ticktick-windows/issues/12)

## For Windows:

Final executable output: [Download Here](https://github.com/Dhanush908090/latest-unlimited-ticktick-windows/tree/latest-tick)

### How to use? 

- Upgrade or Install the original TickTick (Chinese Ticktick/dida365 will not work - personally never tried it).
- Close the app from System tray completely.
- Copy the exe file inside installed path (usually `C:\Program Files (x86)\TickTick`). Have a backup from the original exe file just in case.

### Features

- Unlimited Habits
- Calendar view
- Widgets
- Reminders
- Themes
- ⚠️ Some features might not work if it is restricted on server side

### To learn how its made

- Use dnSpy
- Update these:

Approach 1:

```
// in ticktick_WPF.Models.UserModel
proEndDate=>DateTime.MaxValue;
pro=>true;
```

Approach 2:

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
