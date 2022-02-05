# Freelancer HD Bash Installer

A script to install the [Freelancer HD Mod](https://www.moddb.com/mods/freelancer-hd-edition) using bash.

Not affiliated with the main project. I just ran into a ton of problems getting the official installer to work on Linux, so I put together a quick script that does the job for me.

The first argument to the script is always a valid path to a vanilla (non-modded) install of Freelancer.

The script, like the official installer, can be used both offline and online. If you wish to use the script offline you need to pass the path of the mod .zip file as an argument to the script.

You may need to edit the global variables in the script to reflect your system. The script assumes you have a vanilla install of Freelancer inside a Wine prefix. So just install Freelancer normally using wine and pass the path to the script.

## Usage

```
./installFreelancerHD.sh [/path/to/Freelancer] [/path/to/mod/zipfile]
```

## Dependencies

* `unzip`
* `curl` or `wget` (if using online mode)