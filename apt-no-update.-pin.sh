# no-update.sh This script will assist the user in marking packages that are not to he updated
#
# LGD: Wed Apr 16 11:12:10 AM PDT 2025
# Source: https://www.tecmint.com/disable-lock-blacklist-package-updates-ubuntu-debian-apt/
#
# Created with Google Gemini 2.5: https://aistudio.google.com/prompts/1LfCZpbyR5E_8UibcegynDfzrpA7nNgmI
#

#!/bin/bash
# Using #!/bin/bash for wider compatibility features like [[ ]]
# but aiming for syntax that also works in ksh.
#
# no-update.sh - Manage apt-mark hold/pin status for specified packages.
# Works in bash and ksh. Run as root or with sudo.
# Allows selection by number or first letter (case-insensitive) for main menus.
#

####### Begin Pinning Definitions #######
readonly SCRIPT_PINNING_FILE="/etc/apt/preferences.d/99-no-update-script-pins"
readonly PIN_PRIORITY="-1"
####### End Pinning Definitions #######

# --- Standard Separator ---
readonly SEPARATOR="--------------------------------------------------" # 50 dashes

# --- Setterm Color/Highlighting Functions ---
TERM_SUPPORTS_COLOR=false
if [ -t 1 ] && command -v setterm > /dev/null; then
    if setterm -foreground green > /dev/null 2>&1; then
       setterm -foreground default > /dev/null 2>&1; TERM_SUPPORTS_COLOR=true
    elif setterm -foreground reset > /dev/null 2>&1; then
       setterm -foreground reset > /dev/null 2>&1; TERM_SUPPORTS_COLOR=true
    fi
fi
color_reset() { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground default -background default -bold off -reverse off; }
color_bold()  { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -bold on; }
color_red()   { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground red; }
color_green() { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground green; }
color_yellow(){ [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground yellow; }
color_blue()  { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground blue; }
color_cyan()  { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground cyan; }
color_rev()   { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -reverse on; }


# --- Helper Functions ---
is_installed() {
    pkg_name="$1"; dpkg-query -W -f='${Status}' "$pkg_name" 2>/dev/null | grep -q "ok installed"; return $?
}
is_held() {
    pkg_name="$1"; apt-mark showhold 2>/dev/null | grep -q "^${pkg_name}$"; return $?
}

####### Begin Pinning Functions #######
is_pinned() {
    pkg_name="$1";
    if [ -z "$pkg_name" ]; then echo "Error: is_pinned requires a package name." >&2; return 2; fi
    if [ ! -f "$SCRIPT_PINNING_FILE" ]; then return 1; fi
    awk -v pkg="$pkg_name" -v prio="$PIN_PRIORITY" 'BEGIN { in_stanza=0; exit_code=1 } $0 ~ ("^Package:[[:space:]]*" pkg "[[:space:]]*$") { in_stanza=1; next } in_stanza == 1 && $0 ~ ("^[[:space:]]*Pin-Priority:[[:space:]]*" prio "[[:space:]]*$") { exit_code=0; exit exit_code } in_stanza == 1 && (/^[[:space:]]*$/ || /^Package:/) { in_stanza=0 } END { exit exit_code }' "$SCRIPT_PINNING_FILE" >/dev/null 2>&1
    return $?
}

pin_package() {
    pkg_name="$1"; pin_dir=""
    if [ -z "$pkg_name" ]; then echo "Error: pin_package requires a package name." >&2; return 1; fi
    if is_pinned "$pkg_name"; then return 2; fi
    pin_dir=$(dirname "$SCRIPT_PINNING_FILE")
    if [ ! -d "$pin_dir" ]; then if ! sudo mkdir -p "$pin_dir"; then color_red; echo "Error: Failed to create directory $pin_dir" >&2; color_reset; return 1; fi; fi
    if [ -s "$SCRIPT_PINNING_FILE" ]; then if [ "$(sudo tail -c1 "$SCRIPT_PINNING_FILE" | wc -l)" -eq 0 ]; then printf "\n" | sudo tee -a "$SCRIPT_PINNING_FILE" > /dev/null || return 1; fi; printf "\n" | sudo tee -a "$SCRIPT_PINNING_FILE" > /dev/null || return 1; fi
    printf "Package: %s\n" "$pkg_name"        | sudo tee -a "$SCRIPT_PINNING_FILE" > /dev/null || return 1
    printf "Pin: release *\n"                 | sudo tee -a "$SCRIPT_PINNING_FILE" > /dev/null || return 1
    printf "Pin-Priority: %s\n" "$PIN_PRIORITY" | sudo tee -a "$SCRIPT_PINNING_FILE" > /dev/null || return 1
    sudo chmod 644 "$SCRIPT_PINNING_FILE"
    sync
    if is_pinned "$pkg_name"; then return 0; else color_red; echo "Error: Failed to verify pin for $pkg_name after writing." >&2; color_reset; return 1; fi
}

unpin_package() {
    pkg_name="$1"; temp_file=""; sed_script=""; safe_pkg_name=""; start_pattern=""; end_pattern=""; cleaned_temp_file=""
    file_removed=false; verification_passed=false
    if [ -z "$pkg_name" ]; then echo "Error: unpin_package requires a package name." >&2; return 1; fi
    if ! is_pinned "$pkg_name"; then return 2; fi
    temp_file=$(mktemp); if [ -z "$temp_file" ]; then color_red; echo "Error: Failed to create temporary file." >&2; color_reset; return 1; fi
    trap 'sudo rm -f "$temp_file" "$cleaned_temp_file" 2>/dev/null' EXIT HUP INT QUIT TERM
    safe_pkg_name=$(echo "$pkg_name" | sed -e 's/[]\/$*.^[]/\\&/g')
    start_pattern="^Package:[[:space:]]*${safe_pkg_name}[[:space:]]*$"
    end_pattern="^[[:space:]]*$"
    if ! sudo sed -e "/${start_pattern}/,/${end_pattern}/d" "$SCRIPT_PINNING_FILE" > "$temp_file" 2>/dev/null; then color_red; echo "Error: sed filtering failed during unpin for $pkg_name." >&2; color_reset; trap - EXIT HUP INT QUIT TERM; return 1; fi
    if [ -s "$temp_file" ]; then
        cleaned_temp_file=$(mktemp)
        awk 'NF > 0 {inblock=1; print} /^$/ {if (inblock) print; inblock=0}' "$temp_file" > "$cleaned_temp_file"
        if [ -s "$cleaned_temp_file" ]; then if ! sudo mv "$cleaned_temp_file" "$SCRIPT_PINNING_FILE"; then color_red; echo "Error: Failed to replace pinning file for $pkg_name." >&2; color_reset; sudo rm -f "$temp_file"; trap - EXIT HUP INT QUIT TERM; return 1; fi; sudo rm -f "$temp_file";
        else sudo rm -f "$temp_file" "$cleaned_temp_file"; if ! sudo rm -f "$SCRIPT_PINNING_FILE"; then color_red; echo "Error: Failed to remove original pinning file after cleaning ($pkg_name)." >&2; color_reset; trap - EXIT HUP INT QUIT TERM; return 1; fi; file_removed=true; fi
        sudo chmod 644 "$SCRIPT_PINNING_FILE" 2>/dev/null
    else
        sudo rm -f "$temp_file"
        if ! sudo rm -f "$SCRIPT_PINNING_FILE"; then color_red; echo "Error: Failed to remove empty pinning file for $pkg_name." >&2; color_reset; trap - EXIT HUP INT QUIT TERM; return 1; fi
        file_removed=true
    fi
    sync
    trap - EXIT HUP INT QUIT TERM; sudo rm -f "$temp_file" "$cleaned_temp_file" 2>/dev/null
    if [ "$file_removed" = true ]; then if [ ! -f "$SCRIPT_PINNING_FILE" ]; then verification_passed=true; else color_red; echo "Error: Failed to verify unpin - file still exists after removal attempt for $pkg_name." >&2; color_reset; verification_passed=false; fi
    else if ! is_pinned "$pkg_name"; then verification_passed=true; else color_red; echo "Error: Failed to verify unpin for $pkg_name after filtering (is_pinned check failed)." >&2; color_reset; verification_passed=false; fi; fi
    if [ "$verification_passed" = true ]; then return 0; else return 1; fi
}
####### End Pinning Functions #######

# --- Type Checking Helper Functions ---
is_holdable() { case " $installed_packages_string " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
is_pinnable() { case " $pinnable_packages_string " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
# --- End Type Checking ---

# --- Status and Action Functions ---
print_package_status() {
    pkg_name="$1"; printf "  %-25s : " "$pkg_name"
    if is_installed "$pkg_name"; then
        if is_held "$pkg_name"; then color_yellow; color_bold; printf "%-10s\n" "[ HELD ]"; else color_green; printf "%-10s\n" "[Not Held]"; fi
    else
         if is_pinned "$pkg_name"; then color_red; color_bold; printf "%-10s\n" "[ PINNED ]"; else color_cyan; printf "%-10s\n" "[Not Inst]"; fi
    fi
    color_reset
}

manage_package() {
    action="$1"; pkg_name="$2"; result_msg=""; success=false
    case "$action" in
        hold) if is_held "$pkg_name"; then result_msg="$(color_yellow)Package '$pkg_name' is already held.$(color_reset)"; success=true; else if sudo apt-mark hold "$pkg_name" > /dev/null 2>&1; then result_msg="$(color_green)Successfully held package '$pkg_name'.$(color_reset)"; success=true; else result_msg="$(color_red)Error holding package '$pkg_name'.$(color_reset)"; success=false; fi; fi ;;
        unhold) if ! is_held "$pkg_name"; then result_msg="$(color_yellow)Package '$pkg_name' is not currently held.$(color_reset)"; success=true; else if sudo apt-mark unhold "$pkg_name" > /dev/null 2>&1; then result_msg="$(color_green)Successfully unheld package '$pkg_name'.$(color_reset)"; success=true; else result_msg="$(color_red)Error unholding package '$pkg_name'.$(color_reset)"; success=false; fi; fi ;;
        status) print_package_status "$pkg_name"; success=true ;;
        *) result_msg="$(color_red)Unknown action '$action'.$(color_reset)"; success=false ;;
    esac
    [ "$action" = "hold" -o "$action" = "unhold" ] && [ -n "$result_msg" ] && echo "$result_msg"
    if [ "$success" = true ]; then return 0; else return 1; fi
}
# --- End Status and Action Functions ---

# --- Main Script Logic ---
# 1. Check for root privileges
if [ "$(id -u)" -ne 0 ]; then color_red; color_bold; echo "ERROR: This script must be run as root or using sudo." >&2; color_reset; exit 1; fi

# 2. Check arguments
if [ $# -eq 0 ]; then color_red; color_bold; echo "Usage: sudo $0 <package1> [package2] ..." >&2; color_reset; exit 1; fi

# 3. Validate packages and identify manageable types
installed_packages_string=""
pinnable_packages_string=""
all_manageable_packages_string=""
echo "Validating packages..."
for pkg in "$@"; do
    all_manageable_packages_string="${all_manageable_packages_string}${all_manageable_packages_string:+ }$pkg"
    if is_installed "$pkg"; then
        color_green; printf "  [ OK ]"; color_reset; echo " '$pkg' is installed (Holdable)."
        installed_packages_string="${installed_packages_string}${installed_packages_string:+ }$pkg"
    else
        color_blue; printf "  [INFO]"; color_reset; echo " '$pkg' is not installed (Pinnable)."
        pinnable_packages_string="${pinnable_packages_string}${pinnable_packages_string:+ }$pkg"
    fi
done
printf "%s\n" "$SEPARATOR" # Use standard separator

# 4. Exit if no manageable packages remain
if [ -z "$all_manageable_packages_string" ]; then
    color_red; color_bold; echo "Error: No manageable packages specified or found. Exiting." >&2
    color_reset; exit 1
fi

# 5. Define main menu options string
main_options="Hold/Pin Unhold/Unpin Status Quit"

# 6. Set the main menu prompt
PS3="$(color_blue; color_bold)Select number or letter of action: $(color_reset)"

# 7. Start the main select loop
color_bold; echo "Package Hold/Pin Manager"; color_reset
echo "Working with packages: $(color_yellow)$all_manageable_packages_string$(color_reset)"
printf "%s\n" "$SEPARATOR" # Use standard separator

# Main Loop
select action_choice in $main_options; do
    action_verb=""
    if [ -z "$action_choice" ]; then
        case "$REPLY" in
            [Hh] | [Pp] ) action_choice="Hold/Pin" ;;
            [Uu] ) action_choice="Unhold/Unpin" ;;
            [Ss] ) action_choice="Status" ;;
            [Qq] ) action_choice="Quit" ;;
        esac
    fi

    case "$action_choice" in
        "Hold/Pin") action_verb="set" ;;
        "Unhold/Unpin") action_verb="unset" ;;
        "Status") action_verb="status" ;;
        "Quit") echo "Exiting."; break ;;
        *) color_red; echo "Invalid option '$REPLY'. Please choose number or letter (H/P, U, S, Q)."; color_reset; continue ;;
    esac

    # --- Sub-logic based on action ---
    if [ "$action_verb" = "status" ]; then
        echo; color_bold; echo "--- Current Hold/Pin Status ---"; color_reset # Keep this format
        for pkg in $all_manageable_packages_string; do
             print_package_status "$pkg"
        done
        printf "%s\n" "$SEPARATOR"; color_reset # Use standard separator
    else
        sub_options="All Individual Back"
        if [ "$action_verb" = "set" ]; then prompt_verb="Hold/Pin"; else prompt_verb="Unhold/Unpin"; fi
        PS3_SUB="$(color_blue)Apply '$prompt_verb' to (All/Individual/Back/Letter): $(color_reset)"
        current_ps3="$PS3"; PS3="$PS3_SUB"
        echo
        select sub_choice in $sub_options; do
            if [ -z "$sub_choice" ]; then
                case "$REPLY" in
                    [Aa] ) sub_choice="All" ;;
                    [Ii] ) sub_choice="Individual" ;;
                    [Bb] ) sub_choice="Back" ;;
                esac
            fi
            case "$sub_choice" in
                All)
                    echo; color_bold; echo "--- Applying '$prompt_verb' to all manageable packages ---"; color_reset # Keep this format
                    error_occurred=false
                    for pkg in $installed_packages_string; do
                        if [ "$action_verb" = "set" ]; then manage_package "hold" "$pkg" || error_occurred=true
                        else manage_package "unhold" "$pkg" || error_occurred=true; fi
                    done
                    for pkg in $pinnable_packages_string; do
                         if [ "$action_verb" = "set" ]; then
                            pin_package "$pkg"; ret_code=$?
                            if [ $ret_code -eq 0 ]; then echo "$(color_green)Successfully pinned package '$pkg'.$(color_reset)";
                            elif [ $ret_code -eq 2 ]; then echo "$(color_yellow)Package '$pkg' was already pinned.$(color_reset)";
                            else error_occurred=true; fi
                         else
                            unpin_package "$pkg"; ret_code=$?
                            if [ $ret_code -eq 0 ]; then echo "$(color_green)Successfully unpinned package '$pkg'.$(color_reset)";
                            elif [ $ret_code -eq 2 ]; then echo "$(color_yellow)Package '$pkg' was not pinned (by this script).$(color_reset)";
                            else error_occurred=true; fi
                         fi
                    done
                    if [ "$error_occurred" = false ]; then echo "$(color_green)Action '$prompt_verb' completed for all packages (if applicable).$(color_reset)";
                    else echo "$(color_yellow)Action '$prompt_verb' attempted, some steps may have failed (see messages above).$(color_reset)"; fi
                    printf "%s\n" "$SEPARATOR"; break # Use standard separator
                    ;; # End "All" case

                Individual)
                    pkg_options_string="$all_manageable_packages_string Cancel"
                    PS3_PKG="$(color_blue)Select package to '$prompt_verb' (Num/Cancel): $(color_reset)"
                    current_ps3_sub="$PS3"; PS3="$PS3_PKG"
                    echo
                    select pkg_to_manage in $pkg_options_string; do
                         if [ "$pkg_to_manage" = "Cancel" ]; then echo "Cancelled individual selection."; break;
                         elif [ -n "$pkg_to_manage" ]; then
                              is_valid_selection=false
                              case " $all_manageable_packages_string " in *" $pkg_to_manage "*) is_valid_selection=true ;; esac
                              if [ "$is_valid_selection" = true ]; then
                                  if is_holdable "$pkg_to_manage"; then
                                      if [ "$action_verb" = "set" ]; then manage_package "hold" "$pkg_to_manage";
                                      else manage_package "unhold" "$pkg_to_manage"; fi
                                  elif is_pinnable "$pkg_to_manage"; then
                                      if [ "$action_verb" = "set" ]; then
                                          pin_package "$pkg_to_manage"; ret_code=$?
                                          if [ $ret_code -eq 0 ]; then echo "$(color_green)Successfully pinned package '$pkg_to_manage'.$(color_reset)";
                                          elif [ $ret_code -eq 2 ]; then echo "$(color_yellow)Package '$pkg_to_manage' was already pinned.$(color_reset)"; fi
                                      else
                                          unpin_package "$pkg_to_manage"; ret_code=$?
                                          if [ $ret_code -eq 0 ]; then echo "$(color_green)Successfully unpinned package '$pkg_to_manage'.$(color_reset)";
                                          elif [ $ret_code -eq 2 ]; then echo "$(color_yellow)Package '$pkg_to_manage' was not pinned (by this script).$(color_reset)"; fi
                                      fi
                                  else color_red; echo "Internal Error: Package '$pkg_to_manage' not found in known lists."; color_reset; fi
                                  break
                              else color_red; echo "Invalid selection '$REPLY'. Choose number or Cancel."; color_reset; fi
                         else color_red; echo "Invalid choice '$REPLY'. Please choose number or Cancel."; color_reset; fi
                    done
                    PS3="$current_ps3_sub"; break
                    ;; # End "Individual" case

                Back) break ;;
                *) color_red; echo "Invalid option '$REPLY'. Please choose number or letter (A, I, B)."; color_reset; printf "%s" "$PS3" >&2 ;;
            esac
        done
        PS3="$current_ps3"
    fi

    # --- Returning to main menu ---
    if [ "$action_choice" != "Quit" ]; then
         echo; echo "*** Returning to main menu ***"; echo
    fi

done # End main select loop

color_reset # Final reset
echo "Script finished."
exit 0
