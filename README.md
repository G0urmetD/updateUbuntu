# updateUbuntu
Just a small automation shell script to update Ubuntu systems daily/weekly with different methods.

```Bash
                     _       _       _   _ _                 _
                    | |     | |     | | | | |               | |
     _   _ _ __   __| | __ _| |_ ___| | | | |__  _   _ _ __ | |_ _   _
    | | | | '_ \ / _` |/ _` | __/ _ \ | | | '_ \| | | | '_ \| __| | | |
    | |_| | |_) | (_| | (_| | ||  __/ |_| | |_) | |_| | | | | |_| |_| |
     \__,_| .__/ \__,_|\__,_|\__\___|\___/|_.__/ \__,_|_| |_|\__|\__,_|
          | |
          |_|
 Author: G0urmetD
 Version: 1.4

./updateUbuntu.sh
./updateUbuntu.sh --upgrade-version
./updateUbuntu.sh --delete-snaps
```
## Functionalities
- config file
  - set auto reboot
  - set custom source lists
- checking internet connection
- checking whether sufficient storage space is available and whether the file systems are in order
- creating a simple snapshot of system files
  - deleting automatically snapshots of backup path, which are older than 4 weeks
  - using parameter to delete manually those snapshots: --delete-snaps
- update advanced packages yarn and conda
- update apt packages
- update snap packages
- update flatpak packages
- update npm packages
- update pip/pip3 packages
- update docker containers
- update kernel
- version upgrade (example: 22.04 to 24.04)
  - using parameter: --upgrade-version
- check for unsafe and old packages
