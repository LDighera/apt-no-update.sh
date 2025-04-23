# apt-no-update-pin.sh - APT Hold & Pin Manager

A shell script designed for Debian/Ubuntu-based systems to manage both the "hold" status of installed packages (preventing upgrades) and the "pinning" status of uninstalled packages (preventing installation).

## Purpose

This script enhances package management control by providing a unified command-line menu interface (using the shell's `select` command) to:

*   **Hold/Unhold Installed Packages:** Prevent upgrades for packages already on the system using `apt-mark hold/unhold`.
*   **Pin/Unpin Uninstalled Packages:** Prevent specified packages from being installed by creating a low-priority entry (`Pin-Priority: -1`) in a dedicated APT preferences file.
*   **Check Status:** View the current Hold or Pin status for all specified packages.

It serves users who want fine-grained control over both upgrades and potential installations.

## Requirements

*   **Operating System:** Debian, Ubuntu, or derivatives (uses `apt-mark`, `dpkg-query`, APT preferences).
*   **Shell:** `bash` or `ksh` (tested with modern versions).
*   **Privileges:** Requires `root` privileges (run using `sudo`) to execute `apt-mark` and modify APT preferences.
*   **Commands:** Needs `apt-mark`, `dpkg-query`, `grep`, `id`, `awk`, `sed`, `mktemp`, `sync`, `mv`, `rm`, `tee`, `chmod`, `cat`, `dirname`, `stat`, `tail`, `wc`. Also needs `setterm` (optional, for colors). `setterm` is usually part of the `util-linux` package.

## Usage

1.  **Download:** Get the `apt-no-update-pin.sh` script file.
2.  **Make Executable:** `chmod +x apt-no-update-pin.sh`
3.  **Run with Sudo:** Execute the script with `sudo`, providing the names of the packages you want to manage (installed or uninstalled) as arguments:

    ```bash
    sudo ./apt-no-update-pin.sh <package1> [package2] ...
    ```
    Example:
    ```bash
    # Manage an installed package and one you want to prevent installing
    sudo ./apt-no-update-pin.sh firefox rpi-connect some-other-package
    ```

4.  **Interact with the Menu:**
    *   The script will validate the packages, identifying them as installed (Holdable) or not installed (Pinnable).
    *   A numbered menu will appear:
        ```
        1) Hold/Pin
        2) Unhold/Unpin
        3) Status
        4) Quit
        Select number or letter of action:
        ```
    *   Enter the **number** corresponding to your desired action or the **first letter** (H/P, U, S, Q - case-insensitive).
    *   Follow the sub-prompts to apply the action to all listed packages or select individually. The script will automatically apply "hold/unhold" to installed packages and "pin/unpin" to uninstalled packages.
    *   Select "Quit" or "q" to exit the script.

## Features

*   Unified text-based menu for Hold and Pin management.
*   Manages both installed (hold/unhold) and uninstalled (pin/unpin) packages.
*   Uses `apt-mark` for holding/unholding.
*   Uses a dedicated APT preferences file (`/etc/apt/preferences.d/99-no-update-script-pins`) for pinning, preventing interference with other rules.
*   Checks and displays the current status: `[ HELD ]`, `[Not Held]`, `[ PINNED ]`, `[Not Inst]`.
*   Uses `setterm` for optional color highlighting (if supported).
*   Designed for compatibility with both `bash` and `ksh`.

## Important Notes

*   **Root Required:** Must be run with `sudo` or as root.
*   **Debian/Ubuntu Specific:** Relies on APT package management tools and preferences mechanism.
*   **Pinning File:** Pinning actions modify `/etc/apt/preferences.d/99-no-update-script-pins`. Do not manually edit this file expecting complex pinning scenarios; the script manages simple negative priority pins (`-1`).
*   **Hold vs. Pin:**
    *   **Hold:** Prevents *upgrades* of *installed* packages.
    *   **Pin (Priority -1):** Prevents *installation* (and therefore upgrades) of packages, whether currently installed or not. This script applies pinning only to packages detected as *not installed* at runtime.
*   **Dependencies:** Neither holding nor pinning directly resolves complex dependency conflicts that might arise from holding back core packages. Use with caution.

## Acknowledgements

This script was developed collaboratively with Google Gemini, evolving from a simpler hold-only script (`apt-no-update.sh`).
