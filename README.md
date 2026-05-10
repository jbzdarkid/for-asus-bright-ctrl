# Flicker-Free Dimming Brightness Controls App for MyASUS
This is a simple app that I created to control MyASUS' "Flicker-Free Dimming" brightness with hot keys instead of their GUI.

## Installation for Windows >= 10, x86_64
- Download the latest build from [releases](https://github.com/NH5pml30/for-asus-bright-ctrl/releases);
- Extract the folder. It should contain 5 files:
  - `for-asus-bright-ctrl.exe` - the app;
  - `launch.ps1` - thin launcher invoked by the scheduled task at log-in;
  - `install.ps1`, `uninstall.ps1`, `ensure-rpc.ps1` - (un)installation scripts.
- run `./install.ps1` in PowerShell from the extracted directory. Note that script execution should be enabled, see more [here, for example](https://superuser.com/questions/106360/how-to-enable-execution-of-powershell-scripts). It will display a UAC prompt half-way through, click "Yes" or similar. It is needed to modify the Windows registry.

  This will copy the app and helper scripts into `%LOCALAPPDATA%\for-asus-bright-ctrl` and register two scheduled tasks (`for-asus-bright-ctrl` and `for-asus-bright-ctrl regedit`) to run on every current user's log-in. The extracted folder can be deleted afterwards; re-running `install.ps1` from a newer release upgrades the install in place. Warning: this will disable security checks that the `AsusOptimization.exe` RPC server does by setting a value in the Windows registry, so that this process can communicate with it.

## Uninstall
Run `./uninstall.ps1` (from the extracted folder or from `%LOCALAPPDATA%\for-asus-bright-ctrl`). This will undo those changes.

## How Does it Work
The app tries to find the MyASUS package, locate its RPC client (the part that communicates to `AsusOptimization.exe`, which controls the driver) `.dll` file, copy it over to the working directory, and then load it and call necessary functions to control the brightness through `AsusOptimization.exe`.

## Usage
Controls are:
- `Ctrl + Shift + Win + <`: brightness down 10%;
- `Ctrl + Shift + Win + >`: brightness up 10%;
- `Ctrl + Shift + Win + /`: re-synchronize brightness, for example when changed from MyASUS app in parallel.

Also note that when using HDR these changes are not applied immediately, but it seems that they will be applied when exiting HDR. MyASUS' app in this case does not allow changing the brightness at all, which seems reasonable.

## Screenshots
A little window with the current brightness indicator should appear in the upper-left corner of the screen, when any of the hot keys are pressed:

![image](https://github.com/NH5pml30/for-asus-bright-ctrl/assets/39946761/70fc0cd9-c5c8-4dcb-bac8-01fcca26bbd6)

## Troubleshooting
You can either manually restart the app, or rerun the task from the Task Scheduler. In `%LOCALAPPDATA%\for-asus-bright-ctrl` there should be a `log.txt` file with some logs.

## Building From Source
If you want to build this from source, you will need Visual Studio 2022 with Desktop Development with C++ and MFC libraries. Just build the project and grab the resulting `for-asus-bright-ctrl.exe` file with the scripts from `./scripts` folder in the repo.

Disclaimer: I am not affiliated, associated, authorized, endorsed by, or in any way officially connected with ASUSTek Computer Inc., or any of its subsidiaries or its affiliates. The official ASUS web site is available at https://www.asus.com.

---

## Changes in this fork
[This fork](https://github.com/jbzdarkid/for-asus-bright-ctrl) is functionally identical to the original, but adds a few QoL improvements:

- Permanent install location: The `install.ps1` script now copies files into `%LOCALAPPDATA%\for-asus-bright-ctrl` so that the download can be safely deleted
  - Re-running the install script will also clean this folder out, in case of a bad installation.
- Automated updates: The at-logon task will check for updates and automatically download, install, and restart the executable (update logs are at `update-log.txt`).
  - Automated releases: Commits pushed to the master branch will automatically build and be uploaded as github releases.
- Replaced the `.reg` (un)installation files with direct powershell commands. This helps reduce the size of the update payload.
  - We are also statically linking `mfc140u.dll` to reduce the size of the update payload.
- Fixed a couple of bugs which caused the UI to "hang" or the keyboard to become unresponsive.
- Improved a log message in case you run `for-asus-bright-ctrl.exe` directly out of the install zip, instead of running the installer.
