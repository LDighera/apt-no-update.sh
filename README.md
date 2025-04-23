# apt-no-update.sh - Simple APT Hold/Unhold Manager

A shell script designed for Debian/Ubuntu-based systems to easily manage the "hold" status of installed packages using `apt-mark`. This prevents specified packages from being automatically upgraded during system updates.

## Purpose

This script provides a simple command-line menu interface (using the shell's `select` command) to:
*   Place a package on "hold" (`apt-mark hold`).
*   Remove a package from "hold" (`apt-mark unhold`).
*   Check the current hold status of specified packages.

It primarily helps users prevent unwanted upgrades for specific, *already installed* packages.

## Requirements

*   **Operating System:** Debian, Ubuntu, or derivatives (uses `apt-mark` and `dpkg-query`).
*   **Shell:** `bash` or `ksh` (tested with modern versions).
*   **Privileges:** Requires `root` privileges (run using `sudo`) to execute `apt-mark`.
*   **Commands:** Needs `apt-mark`, `dpkg-query`, `grep`, `id`, `setterm` (optional, for colors). `setterm` is usually part of the `util-linux` package.

## Usage

1.  **Download:** Get the `apt-no-update.sh` script file.
2.  **Make Executable:** `chmod +x apt-no-update.sh`
3.  **Run with Sudo:** Execute the script with `sudo`, providing the names of the *installed* packages you want to manage as arguments:

    ```bash
    sudo ./apt-no-update.sh <package1> [package2] ...
    ```
    Example:
    ```bash
    sudo ./apt-no-update.sh firefox vim-common my-custom-app
    ```

4.  **Interact with the Menu:**
    *   The script will first validate if the provided packages are installed.
    *   A numbered menu will appear:
        ```
        1) Hold
        2) Unhold
        3) Status
        4) Quit
        Select number or letter of action:
        ```
    *   Enter the **number** corresponding to your desired action or the **first letter** (H, U, S, Q - case-insensitive).
    *   Follow the sub-prompts to apply the action to all listed packages or select individually.
    *   Select "Quit" or "q" to exit the script.

## Features

*   Simple text-based menu using `select`.
*   Manages hold status for one or more *installed* packages per invocation.
*   Checks if packages are installed before attempting to manage them.
*   Uses `setterm` for optional color highlighting to improve readability (if supported by the terminal).
*   Designed for compatibility with both `bash` and `ksh`.

## Important Notes

*   **Root Required:** Must be run with `sudo` or as root.
*   **Debian/Ubuntu Specific:** Relies on APT package management tools.
*   **Installed Packages Only:** This script only manages the hold status of packages that are *currently installed*. It does not prevent the installation of new packages.
*   **Hold vs. Removal:** Holding a package prevents upgrades but does not prevent its removal (though package manager dependencies might).

## Acknowledgements

This script was developed with assistance from Google Gemini.
