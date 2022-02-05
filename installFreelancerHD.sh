#!/usr/bin/env bash

# GLOBALS
FLHD_VERSION=0.5
ORIGINAL_FREELANCER_DIR="$1"
FREELANCER_HD_ZIP="$2"
WINETRICKS_DIR="$HOME/.local/share/wineprefixes"
PREFIX_NAME="Games"
DRIVE="$WINETRICKS_DIR/$PREFIX_NAME/drive_c"

ONLINE_MODE=y
FREELANCER_HD_DIR="$DRIVE/users/$USER/AppData/Local/Freelancer HD Edition"
_APP=$FREELANCER_HD_DIR
USERDOCS="$DRIVE/users/$USER/Documents"

# https://github.com/ollieraikkonen/Freelancer-hd-edition-install-script/blob/c7303ba886a4b611c47aba81add615da7c6eb541/setup.iss#L13
declare -a MIRRORS=(
    "https://github.com/BC46/freelancer-hd-edition/archive/refs/tags/0.5.zip"
    "https://onedrive.live.com/download?cid=F03BDD831B77D1AD&resid=F03BDD831B77D1AD%2193138&authkey=AN1qT9jEN5eUIUo"
    "https://pechey.net/files/freelancer-hd-edition-0.5.zip"
    "http://luyten.viewdns.net:8080/freelancer-hd-edition-0.5.0.zip"
    "https://bolte.io/freelancer-hd-edition-0.5.zip"
    "https://archive.org/download/freelancer-hd-edition-0.5/freelancer-hd-edition-0.5.zip"
)

# HELPERS
# crash the script with an ARG1 error message.
_flhd_err() {
    printf "ERROR: %s\n" "$1"
    exit 1
}

# move ARG1 into ARG2, replacing files in the process.
_flhd_move_replace() {
    printf "Moving (& replacing): '%s' -> '%s'\n" "$1" "$2"
    { cp -fal "$1"/* "$2" && rm -rf "$1"; } || _flhd_err "at move/replace operation. ARGS: $*"
}

# copy ARG1 into ARG2, create folder if needed.
_flhd_copy() {
    printf "Copying: '%s' -> '%s'\n" "$1" "$2"
    { cp -r "$1" "$2"; } || _flhd_err "at copy operation. ARGS $*"
}

# Replace ARG1 string with ARG2 string in the ARG3 file.
_flhd_replace_string() {
    printf "Replacing string: '%s' -> '%s'\nIn file: %s\n" "$1" "$2" "$3"
    { sed -i "s/$1/$2/" "$3"; } || _flhd_err "at string replace operation. ARGS $*"
}

# Replace ARG1 file with ARG2 file, ARG1 is not deleted but instead renamed with a suffix.
_flhd_replace_file() {
    local vanilla_suffix
    local file_1_no_ext
    local file_1_ext
    printf "Replacing file: '%s' -> '%s'\n" "$1" "$2"
    vanilla_suffix="_vanilla"
    file_1_no_ext=${1%.*}
    file_1_ext=${1##*.}
    {
        mv -f "$1" "$file_1_no_ext$vanilla_suffix.$file_1_ext"
        mv -f "$2" "$1"
    } || _flhd_err "at file replace operation. ARGS $*"
}

# Unzip an ARG1 archive, replacing files.
_flhd_unzip() {
    printf "Unzipping: '%s'\n" "$1"
    unzip -o "$1" || _flhd_err "at unzip operation. ARGS $*"
}

# Generate an executable script for the user to quickly play FreelancerHD
_flhd_create_exe() {
    local script_dir
    script_dir="$FREELANCER_HD_DIR/playFreelancerHD.sh"

    # shellcheck disable=SC2016
    {
        printf "%s\n\n" '#!/usr/bin/env bash';
        printf "%s\n"   "PREFIX=$WINEPREFIX/$PREFIX_NAME"
        printf "%s\n\n" "GAME=$FREELANCER_HD_DIR/EXE/Freelancer.exe"
        printf "%s\n"   'run() {'
        printf "%s\n"   '   WINEPREFIX=$PREFIX wine "$GAME"'
        printf "%s\n\n" '}'
        printf "%s\n"   'if [ "$1" == "-v" ]; then'
        printf "%s\n"   '   run'
        printf "%s\n"   'else'
        printf "%s\n"   '   run &> /dev/null'
        printf "%s\n"   'fi'
    } > "$script_dir"
}

# Tell the user that ARG1 function is not implemented yet in this script.
_flhd_not_implemented() {
    printf "%s feature has not been implemented yet. Skipping.\n" "$1"
}

# You know when each time an NPC talks to you in-game, they call you Freelancer Alpha 1-1?
# This mod gives you the ability to change that ID code in Single Player!
# Just select any option you like and the NPCs will call you by that.
_flhd_call_sign() {
    _flhd_not_implemented "call_sign"
}

# The default Freelancer startup movie only has a resolution of 720x480.
# This option adds a higher quality version of this intro with a resolution if 1440x960.
# However, this HD intro is only available in English.
# If you'd like to view the Freelancer intro your game's original language other than English, disable this option.
_flhd_HD_freelancer_intro() {
    local freelancer_intro_path
    freelancer_intro_path="$_APP/DATA/MOVIES"

    _flhd_replace_file "$freelancer_intro_path/fl_intro.wmv" "$freelancer_intro_path/fl_intro_en_hd.wmv"
}

# This option fixes many typos, grammar mistakes, inconsistencies, and more, in the English Freelancer text resources.
# NOTE: This option will set all of Freelancer''s text to English.
# Disable this option if your intention is to play Freelancer in a different language like German, French, or Russian.
_flhd_text_string_revision() {
    cd "$_APP/EXE" || _flhd_err "'$_APP/EXE' not found."
    _flhd_replace_file "resources.dll" "resources_tsr.dll"
    _flhd_replace_file "offerbriberesources.dll" "offerbriberesources_tsr.dll"
    _flhd_replace_file "nameresources.dll" "nameresources_tsr.dll"
    _flhd_replace_file "misctextinfo2.dll" "misctextinfo2_tsr.dll"
    _flhd_replace_file "misctext.dll" "misctext_tsr.dll"
    _flhd_replace_file "infocards.dll" "infocards_tsr.dll"
    _flhd_replace_file "equipresources.dll" "equipresources_tsr.dll"
    cd "$_APP" || _flhd_err "'$_APP' not found."
}

# This option allows you to choose the Single Player mode.
# Story Mode simply lets you play through the entire storyline, as usual.
# Both Open Single Player options skip the entire storyline and allow you to freely roam the universe right away.
# With OSP (Normal), you start in Manhattan with a basic loadout and a default reputation.
# The OSP (Pirate) option on the other hand, spawns you at Rochester with a similar loadout and an inverted reputation.
# NOTE: Both OSP options may cause existing storyline saves to not work correctly.
_flhd_single_player_mode() {
    local new_player_path
    local mission13_path
    new_player_path="$_APP/EXE/newplayer.fl"
    mission13_path="$_APP/DATA/MISSIONS/M13"

    _flhd_replace_string "Mission = Mission_01a" "Mission = Mission_13" "$new_player_path"
    _flhd_replace_file "$mission13_path/m13.ini" "$mission13_path/m13_opensp_normal.ini"
}

# Normally Freelancer save games are stored in "Documents/My Games/Freelancer".
# This option ensures save games will be stored in "Documents/My Games/FreelancerHD" instead,
# which may help avoid conflicts when having multiple mods installed simultaneously.
_flhd_new_save_folder() {
    local flplusplus_path
    flplusplus_path="$_APP/EXE/flplusplus.ini"

    _flhd_replace_string "save_folder_name = Freelancer" "save_folder_name = FreelancerHD" "$flplusplus_path"
}

# By default, the "Freelancer" splash screen you see when you start the game has a resolution of 1280x960.
# This makes it appear stretched and a bit blurry on HD 16:9 resolutions.
# We recommend setting this option to your monitor's native resolution.
# Please note that a higher resolution option may negatively impact the game's start-up speed.
_flhd_startup_res() {
    local folder_path
    local new_file
    folder_path="$_APP/DATA/INTERFACE/INTRO/IMAGES"
    new_file="$folder_path/startupscreen_1280.tga"

    _flhd_replace_file "$new_file" "$folder_path/startupscreen_1280_1920x1080.tga"
}

# Freelancer Logo Resolution in the game's main menu
# This logo has a resolution of 800x600 by default, which makes it look stretched and pixelated/blurry on HD 16:9 monitors.
# Setting this to a higher resolution with the correct aspect ratio makes the logo look nice and sharp and not stretched-out.
# Hence we recommend setting this option to your monitor's native resolution.
# Please note that a higher resolution option may negatively impact the game's start-up speed.
_flhd_logo_res() {
    local folder_path
    local new_file
    folder_path="$_APP/DATA/INTERFACE/INTRO/IMAGES"
    new_file="$folder_path/front_freelancerlogo.tga"

    _flhd_replace_file "$new_file" "$folder_path/front_freelancerlogo_1920x1080.tga"
}

# Fix small text on 1440p/4K resolutions
# Many high-resolution Freelancer players have reported missing HUD text and misaligned buttons in menus.
# In 4K, the nav map text is too small and there are many missing text elements in the HUD.
# For 1440p screens, the only apparent issue is the small nav map text.
# Select the option corresponding to the resolution you''re going to play Freelancer in.
# If you play in 1920x1080 or lower, the "No" option is fine as the elements are configured correctly already.
_flhd_small_text() {
    _flhd_not_implemented "small_text"
}

# This option adds two new useful widgets to your HUD. Next to your contact list,
# you will have a wireframe representation of your selected target.
# Next to your weapons list, you will have a wireframe of your own ship. Disable this option if you play in 4:3.
# If you choose to enable this option, go to the Controls settings in-game and under "User Interface",
# disable Target View (Alt + T). This key binding has become obsolete as both the target view
# and contact list are visible simultaneously.
_flhd_adv_widescreen_hud() {
    local hudshift_path
    local dacom_path
    hudshift_path="$_APP/DATA/INTERFACE/HudShift.ini"
    dacom_path="$_APP/EXE/dacom.ini"

    _flhd_replace_string ";HudFacility.dll" "HudFacility.dll" "$dacom_path"
    _flhd_replace_string ";HudTarget.dll" "HudTarget.dll" "$dacom_path"
    _flhd_replace_string ";HudStatus.dll" "HudStatus.dll" "$dacom_path"

    _flhd_replace_string \
        "position = 4e0a80, -0.3630, 4e0a94, -0.3025		; wireframe" \
        "position = 4e0a80, -0.1245, 4e0a94, -0.2935		; wireframe" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e10ff, -0.4820, 4e1107, -0.2000		; TargetShipName" \
        "position = 4e10ff, -0.2430, 4e1107, -0.2030		; TargetShipName" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e1145, -0.4820, 4e1158, -0.2000" \
        "position = 4e1145, -0.2430, 4e1158, -0.2030" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e1180, -0.4820, 4e1188, -0.2180		; SubtargetName" \
        "position = 4e1180, -0.2430, 4e1188, -0.2210		; SubtargetName" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e11e2, -0.4820, 4e11f0, -0.2180" \
        "position = 4e11e2, -0.2430, 4e11f0, -0.2210" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e1247, -0.2650, 4e124f, -0.2695		; TargetPreviousButton" \
        "position = 4e1247, -0.0595, 4e124f, -0.2780		; TargetPreviousButton" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e12b4, -0.2650, 4e12bc, -0.3005		; TargetNextButton" \
        "position = 4e12b4, -0.0595, 4e12bc, -0.3090		; TargetNextButton" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e175c, -0.4940, 4e1764, -0.3610		; TargetRankText" \
        "position = 4e175c, -0.2550, 4e1764, -0.3610		; TargetRankText" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4da2fa,  0.4180, 4da30e, -0.2900" \
        "position = 4da2fa,  0.1765, 4da30e, -0.3025" \
        "$hudshift_path"
    _flhd_replace_string \
        "position = 4e14db, -0.2020, 4e14e3, -0.3700		; TargetTradeButton" \
        "position = 4e14db, -0.0180, 4e14e3, -0.3700		; TargetTradeButton" \
        "$hudshift_path"
}

# This option adds buttons for selecting 3 different weapon groups in your ship info panel.
# NOTE: These buttons may not be positioned correctly on aspect ratios other than 16:9.
_flhd_weapon_groups() {
    local hudshift_path
    local dacom_path
    hudshift_path="$_APP/DATA/INTERFACE/HudShift.ini"
    dacom_path="$_APP/EXE/dacom.ini"

    _flhd_replace_string ";HudWeaponGroups = true" "HudWeaponGroups = true" "$hudshift_path"
    _flhd_replace_string ";HudWeaponGroups.dll"    "HudWeaponGroups.dll" "$dacom_path"
}

# This option replaces the default Freelancer HUD with a more darker-themed HUD.
# If this option is disabled, you''ll get the HD default HUD instead.
_flhd_dark_hud() {
    _flhd_not_implemented "dark_hud"
}

# This option replaces Freelancer''s default icon set with new simpler flat-looking icons.
# If this option is disabled, you''ll get the HD vanilla icons instead.
_flhd_flat_icons() {
    _flhd_not_implemented "flat_icons"
}

# Since Freelancer was never optimized for 16:9 resolutions, there are several inconsistencies with planetscapes
# that occur while viewing them in 16:9, such as clipping and geometry issues.
# This mod gives you the option of fixing this, as it adjusts the
# camera values in the planetscapes so the issues are no longer visible in 16:9 resolutions.
# Disable this option if you play in 4:3.
# Also please note that this option may yield strange results when using it with an ultrawide resolution.
_flhd_planetscape() {
    local planetscape_path
    planetscape_path="$_APP/DATA/SCRIPTS/BASES"

    cd "$planetscape_path" || _flhd_err "'$planetscape_path' not found."
    _flhd_replace_file "br_01_cityscape_hardpoint_01.thn" "br_01_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "br_02_cityscape_hardpoint_01.thn" "br_02_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "br_03_cityscape_hardpoint_01.thn" "br_03_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "bw_01_cityscape_hardpoint_01.thn" "bw_01_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "bw_02_cityscape_hardpoint_01.thn" "bw_02_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "hi_01_cityscape_hardpoint_01.thn" "hi_01_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "hi_02_cityscape_hardpoint_01.thn" "hi_02_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "ku_01_cityscape_hardpoint_01.thn" "ku_01_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "ku_02_cityscape_hardpoint_01.thn" "ku_02_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "ku_03_cityscape_hardpoint_01.thn" "ku_03_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "li_01_cityscape_hardpoint_01.thn" "li_01_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "li_02_cityscape_hardpoint_01.thn" "li_02_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "li_03_cityscape_hardpoint_01.thn" "li_03_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "li_04_cityscape_hardpoint_01.thn" "li_04_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "rh_01_cityscape_hardpoint_01.thn" "rh_01_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "rh_02_cityscape_hardpoint_01.thn" "rh_02_cityscape_hardpoint_01_169.thn"
    _flhd_replace_file "rh_03_cityscape_hardpoint_01.thn" "rh_03_cityscape_hardpoint_01_169.thn"
    cd "$_APP" || _flhd_err "'$_APP' not found."
}

_flhd_dxwrapper() {
    local dxwrapper_path
    local exe_path
    dxwrapper_path="$_APP/EXE/dxwrapper.ini"
    exe_path="$_APP/EXE"

    mv -f "$exe_path/d3d8_dxwrapper.dll" "$exe_path/d3d8.dll"
    # AA
    _flhd_replace_string "AntiAliasing               = 0" "AntiAliasing               = 1" "$dxwrapper_path"
    # AF
    _flhd_replace_string "AnisotropicFiltering       = 0" "AnisotropicFiltering       = 8" "$dxwrapper_path"
}

# This option changes the way light reflects off ships, bases, etc.
# The shiny option is recommended since vanilla looks quite dull.
# Shiniest on the other hand makes all surfaces very reflective, which most users may not like.
_flhd_shiny_reflections() {
    _flhd_replace_file "$_APP/DATA/FX/envmapbasic.mat" "$_APP/DATA/FX/envmapbasic_shiny.mat"
}

# This option adds custom missile and torpedo effects.
# They're not necessarily higher quality, just alternatives. This option also make torpedoes look massive.
_flhd_missile_effects() {
    local missile_path
    missile_path="$_APP/DATA/FX/WEAPONS"

    cd "$missile_path" || _flhd_err "'$missile_path' not found."
    _flhd_replace_file "br_empmissile.ale" "br_empmissile_new.ale"
    _flhd_replace_file "br_missile01.ale"  "br_missile01_new.ale"
    _flhd_replace_file "br_missile02.ale"  "br_missile02_new.ale"
    _flhd_replace_file "ku_empmissile.ale" "ku_empmissile_new.ale"
    _flhd_replace_file "ku_missile01.ale"  "ku_missile01_new.ale"
    _flhd_replace_file "ku_missile02.ale"  "ku_missile02_new.ale"
    _flhd_replace_file "ku_torpedo01.ale"  "ku_torpedo01_new.ale"
    _flhd_replace_file "li_empmissile.ale" "li_empmissile_new.ale"
    _flhd_replace_file "li_missile01.ale"  "li_missile01_new.ale"
    _flhd_replace_file "li_missile02.ale"  "li_missile02_new.ale"
    _flhd_replace_file "li_torpedo01.ale"  "li_torpedo01_new.ale"
    _flhd_replace_file "pi_missile01.ale"  "pi_missile01_new.ale"
    _flhd_replace_file "pi_missile02.ale"  "pi_missile02_new.ale"
    _flhd_replace_file "rh_empmissile.ale" "rh_empmissile_new.ale"
    _flhd_replace_file "rh_missile01.ale"  "rh_missile01_new.ale"
    _flhd_replace_file "rh_missile02.ale"  "rh_missile02_new.ale"
    cd "$_APP" || _flhd_err "'$_APP' not found."
}

# In vanilla Freelancer, NPC ships have engine trails while player ships don't. This option adds engine trails to all player ships.
_flhd_engine_trails() {
    _flhd_replace_file "$_APP/DATA/EQUIPMENT/engine_equip.ini" "$_APP/DATA/EQUIPMENT/engine_equip_player_trails.ini"
}

# This option sets the draw distances scale; changing it to a higher value allows you to see things in space from further away.
# 1x will give you the same draw distances as vanilla Freelancer.
# Every option after that scales the vanilla values by a multiplier (2x, 3x, etc).
# The Maximized option sets all draw distances to the highest possible values, which includes the jump hole visibility distances.
_flhd_draw_distances() {
    local file_path
    file_path="$_APP/EXE/flplusplus.ini"

    _flhd_replace_string "lod_scale = 9" "lod_scale = 6" "$file_path"
}

# This option allows you to change the duration of the jump tunnels which you go through when using any jump hole or jump gate.
_flhd_jump_tunnel() {
    local file_path
    file_path="$_APP/DATA/FX/jumpeffect.ini"

    _flhd_replace_string "jump_out_tunnel_time = 7" "jump_out_tunnel_time = 1.75" "$file_path"
    _flhd_replace_string "jump_in_tunnel_time = 3"  "jump_in_tunnel_time = 0.75" "$file_path"
}

# This option skips the 3 movies that play when the game starts,
# which include the Microsoft logo, Digital Anvil logo, and Freelancer intro.
_flhd_skip_intros() {
    local file_path
    file_path="$_APP/EXE/freelancer.ini"

    _flhd_replace_string 'movie_file = movies\MGS_Logo_Final.wmv' ';movie_file = movies\MGS_Logo_Final.wmv' "$file_path"
    _flhd_replace_string 'movie_file = movies\DA_Logo_Final.wmv'  ';movie_file = movies\DA_Logo_Final.wmv' "$file_path"
    _flhd_replace_string 'movie_file = movies\FL_Intro.wmv'       ';movie_file = movies\FL_Intro.wmv' "$file_path"
}

# This option provides various console commands in Single Player to directly manipulate the environment.
# It also allows players to own more than one ship.
# To use it, press Enter while in-game and type "help" for a list of available commands.
_flhd_console() {
    _flhd_replace_string ";console.dll" "console.dll" "$_APP/EXE/dacom.ini"
}

## -- BEGIN -- ##

[[ -z "$1" ]] && _flhd_err "The path to a vanilla install of Freelancer must be passed as the first argument to this script."

if [[ -z "$2" ]]; then
    printf "%s\n" "Script is in online mode. To use offline mode pass the .zip path to this script as the second argument."
else
    ONLINE_MODE=n
fi

# COPY ORIGINAL FREELANCER FILES TO FREELANCER HD DIRECTORY
_flhd_copy "$ORIGINAL_FREELANCER_DIR" "$FREELANCER_HD_DIR"

if [[ $ONLINE_MODE == "y" ]]; then
    # DOWNLOAD ZIP FILE TO DESTINATION
    if command -v curl; then
        for i in "${!MIRRORS[@]}"; do
            curl "${MIRRORS[i]}" -o "$FREELANCER_HD_DIR/flhd.zip" \
                && break \
                || printf "%s\n" "Download failed. Retrying automatically with next mirror."
        done
    elif command -v wget; then
        for i in "${!MIRRORS[@]}"; do
            wget "${MIRRORS[i]}" -O "$FREELANCER_HD_DIR/flhd.zip" \
                && break \
                || printf "%s\n" "Download failed. Retrying automatically with next mirror."
        done
    else
        _flhd_err "You need either wget or curl to use this script in online mode."
    fi

    if [[ ! -f "$FREELANCER_HD_DIR/flhd.zip" ]]; then
        _flhd_err "All download mirrors failed, could not install."
    fi
else
    # COPY ZIP FILE TO DESTINATION
    _flhd_copy "$FREELANCER_HD_ZIP" "$FREELANCER_HD_DIR/flhd.zip"
fi

# UNZIP
cd "$FREELANCER_HD_DIR" || _flhd_err "'$FREELANCER_HD_DIR' not found."
_flhd_unzip "$FREELANCER_HD_DIR/flhd.zip" \
    && rm "$FREELANCER_HD_DIR/flhd.zip"

# INSTALL
_flhd_move_replace "$FREELANCER_HD_DIR/freelancer-hd-edition-$FLHD_VERSION" "$FREELANCER_HD_DIR"

# PROCESS OPTIONS
_flhd_call_sign
_flhd_HD_freelancer_intro
_flhd_text_string_revision
_flhd_single_player_mode
# _flhd_new_save_folder
_flhd_startup_res
_flhd_logo_res
# _flhd_small_text
_flhd_console
_flhd_shiny_reflections
_flhd_missile_effects
_flhd_engine_trails
_flhd_skip_intros
_flhd_jump_tunnel
_flhd_draw_distances
_flhd_planetscape
_flhd_adv_widescreen_hud
# _flhd_dark_hud
# _flhd_flat_icons
_flhd_weapon_groups
_flhd_dxwrapper

# Delete Restart.fl to prevent crashes
rm -f "$USERDOCS/My Games/Freelancer/Accts/SinglePlayer/Restart.fl" &> /dev/null
rm -f "$USERDOCS/My Games/FreelancerHD/Accts/SinglePlayer/Restart.fl" &> /dev/null

printf "%s\n" "Install complete!"
_flhd_create_exe