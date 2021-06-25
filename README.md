# Premium TickTick Windows Client

## How to use? 

Copy the exe file inside installed path (usually `C:\Program Files (x86)\TickTick`)

Features
+ All Premium features available
+ Disable Update
+ Version 3.9.1.0

## How I made it

Simply forced `ticktick_WPF.Models.UserModel.proEndDate=>new DateTime?(new DateTime(2030, 12, 25));` and `ticktick_WPF.pro=>true;`
