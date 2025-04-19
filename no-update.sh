# no-update.sh This script will assist the user in marking packages
that are not to he updated
#
# LGD: Wed Apr 16 11:12:10 AM PDT 2025
# Source: https://www.tecmint.com/disable-lock-blacklist-package-updates-ubuntu-debian-apt/
#
# Created with Google Gemini 2.5:
https://aistudio.google.com/prompts/1LfCZpbyR5E_8UibcegynDfzrpA7nNgmI
#

#!/bin/bash
# Using #!/bin/bash for wider compatibility features like [[ ]]
# but aiming for syntax that also works in ksh.
#
# no-update.sh - Manage apt-mark hold status for specified packages.
# Works in bash and ksh. Run as root or with sudo.
# Allows selection by number or first letter (case-insensitive) for main menus.

# --- Setterm Color/Highlighting Functions ---
TERM_SUPPORTS_COLOR=false
if [ -t 1 ] && command -v setterm > /dev/null; then
    if setterm -foreground green > /dev/null 2>&1; then
       setterm -foreground default > /dev/null 2>&1; TERM_SUPPORTS_COLOR=true
    elif setterm -foreground reset > /dev/null 2>&1; then
       setterm -foreground reset > /dev/null 2>&1; TERM_SUPPORTS_COLOR=true
    fi
fi
color_reset() { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm
-foreground default -background default -bold off -reverse off; }
color_bold()  { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -bold on; }
color_red()   { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground red; }
color_green() { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm
-foreground green; }
color_yellow(){ [ "$TERM_SUPPORTS_COLOR" = true ] && setterm
-foreground yellow; }
color_blue()  { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -foreground blue; }
color_rev()   { [ "$TERM_SUPPORTS_COLOR" = true ] && setterm -reverse on; }

# --- Helper Functions ---
is_installed() {
    pkg_name="$1"; dpkg-query -W -f='${Status}' "$pkg_name"
2>/dev/null | grep -q "ok installed"; return $?
}
is_held() {
    pkg_name="$1"; apt-mark showhold 2>/dev/null | grep -q
"^${pkg_name}$"; return $?
}
print_package_status() {
    pkg_name="$1"; printf "  %-25s : " "$pkg_name"
    if is_held "$pkg_name"; then color_yellow; color_bold; printf
"%-10s\n" "[ HELD ]"; else color_green; printf "%-10s\n" "[Not Held]";
fi
    color_reset # Reset after printing status line
}
manage_package() {
    action="$1"; pkg_name="$2"; result_msg=""; success=false
    case "$action" in
        hold)   if is_held "$pkg_name"; then
result_msg="$(color_yellow)Package '$pkg_name' is already
held.$(color_reset)"; success=true; else
                    if sudo apt-mark hold "$pkg_name" > /dev/null
2>&1; then result_msg="$(color_green)Successfully held package
'$pkg_name'.$(color_reset)"; success=true; else
result_msg="$(color_red)Error holding package
'$pkg_name'.$(color_reset)"; success=false; fi
                fi ;;
        unhold) if ! is_held "$pkg_name"; then
result_msg="$(color_yellow)Package '$pkg_name' is not currently
held.$(color_reset)"; success=true; else
                    if sudo apt-mark unhold "$pkg_name" > /dev/null
2>&1; then result_msg="$(color_green)Successfully unheld package
'$pkg_name'.$(color_reset)"; success=true; else
result_msg="$(color_red)Error unholding package
'$pkg_name'.$(color_reset)"; success=false; fi
                fi ;;
        status) print_package_status "$pkg_name"; success=true ;;
        *)      result_msg="$(color_red)Unknown action
'$action'.$(color_reset)"; success=false ;;
    esac
    [ "$action" != "status" -a -n "$result_msg" ] && echo "$result_msg"
    if [ "$success" = true ]; then return 0; else return 1; fi
}

# --- Main Script Logic ---
# 1. Check for root privileges
if [ "$(id -u)" -ne 0 ]; then color_red; color_bold; echo "ERROR: This
script must be run as root or using sudo." >&2; color_reset; exit 1;
fi

# 2. Check arguments
if [ $# -eq 0 ]; then color_red; color_bold; echo "Usage: sudo $0
<package1> [package2] ..." >&2; color_reset; exit 1; fi

# 3. Validate packages
valid_packages_string=""
echo "Validating packages..."
for pkg in "$@"; do
    if is_installed "$pkg"; then color_green; printf "  [ OK ]";
color_reset; echo " '$pkg' is installed.";
valid_packages_string="${valid_packages_string}${valid_packages_string:+
}$pkg";
    else color_red; printf "  [WARN]"; color_reset; echo " Package
'$pkg' is not installed or not found. Skipping."; fi
done
echo "-------------------------------------"

# 4. Exit if no valid packages
if [ -z "$valid_packages_string" ]; then color_red; color_bold; echo
"Error: None of the specified packages are installed. Exiting." >&2;
color_reset; exit 1; fi

# 5. Define main menu options string
main_options="Hold Unhold Status Quit"

# 6. Set the main menu prompt
PS3="$(color_blue; color_bold)Select number or letter of action: $(color_reset)"

# 7. Start the main select loop
color_bold; echo "Package Hold Manager"; color_reset
echo "Working with packages:
$(color_yellow)$valid_packages_string$(color_reset)"
echo "-------------------------------------"

# Let select handle the initial menu/prompt display

# Main Loop
select action_choice in $main_options; do

    # Check $REPLY for letter shortcuts if $action_choice is empty
    if [ -z "$action_choice" ]; then
        case "$REPLY" in
            [Hh] | [Hh][Oo][Ll][Dd] ) action_choice="Hold" ;;
            [Uu] | [Uu][Nn][Hh][Oo][Ll][Dd] ) action_choice="Unhold" ;;
            [Ss] | [Ss][Tt][Aa][Tt][Uu][Ss] ) action_choice="Status" ;;
            [Qq] | [Qq][Uu][Ii][Tt] ) action_choice="Quit" ;;
        esac
    fi

    # Process the choice
    case "$action_choice" in
        Hold) action_verb="hold" ;;
        Unhold) action_verb="unhold" ;;
        Status) action_verb="status" ;;
        Quit)
            echo "Exiting."
            break
            ;;
        *) # Invalid input in main menu
            color_red; echo "Invalid option '$REPLY'. Please choose a
number or the first letter (H, U, S, Q)."; color_reset
            # *** REMOVED manual prompt printing here ***
            continue # Let select redisplay prompt automatically
            ;;
    esac

    # --- Sub-logic based on action ---
    if [ "$action_verb" = "status" ]; then
        echo; color_bold; echo "--- Current Hold Status ---"; color_reset
        for pkg in $valid_packages_string; do manage_package "status"
"$pkg"; done
        echo "---------------------------"; color_reset
    else
        # Sub-menu for Hold/Unhold
        sub_options="All Individual Back"
        PS3_SUB="$(color_blue)Apply '$action_verb' to
(All/Individual/Back/Letter): $(color_reset)"
        current_ps3="$PS3"; PS3="$PS3_SUB"

        echo # Add newline before sub-menu
        select sub_choice in $sub_options; do
            # Check REPLY for sub-menu letters
            if [ -z "$sub_choice" ]; then
                case "$REPLY" in
                    [Aa] | [Aa][Ll][Ll] ) sub_choice="All" ;;
                    [Ii] | [Ii][Nn][Dd]*) sub_choice="Individual" ;;
                    [Bb] | [Bb][Aa][Cc][Kk] ) sub_choice="Back" ;;
                esac
            fi

            case "$sub_choice" in
                All)
                    echo; color_bold; echo "--- Applying
'$action_verb' to all valid packages ---"; color_reset
                    all_success=true; for pkg in
$valid_packages_string; do manage_package "$action_verb" "$pkg" ||
all_success=false; done
                    if [ "$all_success" = true ]; then echo
"$(color_green)Action '$action_verb' completed for all packages (if
applicable).$(color_reset)"; else echo "$(color_yellow)Action
'$action_verb' attempted, some steps may have failed.$(color_reset)";
fi
                    echo
"-------------------------------------------------"; break
                    ;;
                Individual)
                    pkg_options_string="$valid_packages_string Cancel"
                    PS3_PKG="$(color_blue)Select package to
'$action_verb' (Num/Cancel): $(color_reset)"
                    current_ps3_sub="$PS3"; PS3="$PS3_PKG"

                    echo # Add newline before package list
                    select pkg_to_manage in $pkg_options_string; do
                         if [ "$pkg_to_manage" = "Cancel" ]; then echo
"Cancelled individual selection."; break;
                         elif [ -n "$pkg_to_manage" ]; then
                              is_valid_selection=false; for valid in
$valid_packages_string; do [ "$valid" = "$pkg_to_manage" ] && {
is_valid_selection=true; break; }; done
                              if [ "$is_valid_selection" = true ];
then manage_package "$action_verb" "$pkg_to_manage"; break;
                              else color_red; echo "Invalid selection
'$REPLY'. Choose number or Cancel."; color_reset; fi
                         else color_red; echo "Invalid choice
'$REPLY'. Please choose number or Cancel."; color_reset; fi
                         # Let select redisplay prompt automatically after error
                    done # End package select loop
                    PS3="$current_ps3_sub"; break # Exit sub-menu loop
                    ;;
                Back) break ;;
                *) # Invalid input in All/Individual/Back menu
                   color_red; echo "Invalid option '$REPLY'. Please
choose number or letter (A, I, B)."; color_reset
                    # Force prompt redisplay after error in this
sub-menu (can be kept if desired)
                    printf "%s" "$PS3" >&2
                    ;;
            esac
        done # End sub-menu select loop
        PS3="$current_ps3" # Restore main menu prompt
    fi

    # --- Returning to main menu ---
    if [ "$action_choice" != "Quit" ]; then
         echo; echo "*** Returning to main menu ***"; echo
         # Let select display the next menu/prompt automatically
    fi

done # End main select loop

color_reset # Final reset
echo "Script finished."
exit 0
