# Premium TickTick Windows Client

All Premium features UNLOCKED.

[Download Here](https://github.com/yazdipour/cracked-ticktick-windows/releases)

## How to use? 

- Upgrade or Install the original TickTick (Chinese Ticktick/dida365 will not work).
- Close the app from System tray completely.
- Copy the exe file inside installed path (usually `C:\Program Files (x86)\TickTick`). Have a backup from the original exe file just in case.
- Enjoy!

## Features

- Unlimited Habits
- Calendar view
- ~Calendar Subscription~
- Maintain third-party calendar subscription (If you subscribe your calendar via Paid Ticktick (maybe even with trials version), after opting-out you can still use it)
- Widgets
- Reminders
- Themes
- Smoother Focus experience 

## How I made it

- Use dnSpy
- Update these:

Approach 1:

```
// in ticktick_WPF.Models.UserModel
proEndDate=>new DateTime?(new DateTime(2030, 12, 25));
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
