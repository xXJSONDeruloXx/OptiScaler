#!/bin/bash

# Setup OptiScaler for your game (Linux version)
clear

echo " ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  "
echo ":+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: "
echo "#+:    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ "
echo "+#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  "
echo "+#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ "
echo "#+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# "
echo " ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### "
echo ""
echo "Coping is strong with this one..."
echo ""

# Remove extraction marker file if it exists
rm -f "!! EXTRACT ALL FILES TO GAME FOLDER !!" 2>/dev/null

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_PATH="$SCRIPT_DIR"
OPTISCALER_FILE="$GAME_PATH/OptiScaler.dll"
SETUP_SUCCESS=false

# Check if OptiScaler.dll exists
if [ ! -f "OptiScaler.dll" ]; then
    echo "OptiScaler \"OptiScaler.dll\" file is not found!"
    echo "Please make sure you extracted all OptiScaler files to the game folder."
    echo ""
    echo "For Unreal Engine games, look for the game executable in:"
    echo "- <path-to-game>/Game-or-Project-name/Binaries/Win64/"
    echo "- Ignore the Engine folder"
    echo ""
    read -p "Press Enter to exit..."
    exit 1
fi

# Check if the Engine folder exists (Unreal Engine detection)
if [ -d "$GAME_PATH/Engine" ]; then
    echo "Found Engine folder, if this is an Unreal Engine game then please extract OptiScaler to #CODENAME#/Binaries/Win64"
    echo ""
    
    while true; do
        read -p "Continue installation to current folder? [y/n]: " continue_choice
        continue_choice=$(echo "$continue_choice" | tr -d ' ')
        
        if [ "$continue_choice" = "y" ] || [ "$continue_choice" = "Y" ]; then
            break
        elif [ "$continue_choice" = "n" ] || [ "$continue_choice" = "N" ]; then
            echo "Installation cancelled."
            read -p "Press Enter to exit..."
            exit 0
        fi
    done
fi

# Function to select filename
select_filename() {
    while true; do
        echo ""
        echo "Choose a filename for OptiScaler (default is dxgi.dll):"
        echo " [1] dxgi.dll"
        echo " [2] winmm.dll"
        echo " [3] version.dll"
        echo " [4] dbghelp.dll"
        echo " [5] d3d12.dll"
        echo " [6] wininet.dll"
        echo " [7] winhttp.dll"
        echo " [8] OptiScaler.asi"
        
        read -p "Enter 1-8 (or press Enter for default): " filename_choice
        
        case "$filename_choice" in
            ""|"1")
                selected_filename="dxgi.dll"
                ;;
            "2")
                selected_filename="winmm.dll"
                ;;
            "3")
                selected_filename="version.dll"
                ;;
            "4")
                selected_filename="dbghelp.dll"
                ;;
            "5")
                selected_filename="d3d12.dll"
                ;;
            "6")
                selected_filename="wininet.dll"
                ;;
            "7")
                selected_filename="winhttp.dll"
                ;;
            "8")
                selected_filename="OptiScaler.asi"
                ;;
            *)
                echo "Invalid choice. Please select a valid option."
                echo ""
                continue
                ;;
        esac
        
        # Check if file already exists
        if [ -f "$selected_filename" ]; then
            echo ""
            echo "WARNING: $selected_filename already exists in the current folder."
            echo ""
            
            while true; do
                read -p "Do you want to overwrite $selected_filename? [y/n]: " overwrite_choice
                overwrite_choice=$(echo "$overwrite_choice" | tr -d ' ')
                
                if [ "$overwrite_choice" = "y" ] || [ "$overwrite_choice" = "Y" ]; then
                    break 2  # Break out of both loops
                elif [ "$overwrite_choice" = "n" ] || [ "$overwrite_choice" = "N" ]; then
                    break  # Break inner loop, continue filename selection
                fi
            done
        else
            break  # File doesn't exist, proceed
        fi
    done
}

# Call filename selection function
select_filename

# Since we're on Linux, we skip Wine detection and go straight to GPU configuration
echo ""
echo "Running on Linux - spoofing configuration will be handled automatically."
echo "If you need to disable spoofing, you can set Dxgi=false in the config"
echo ""

# Try to detect GPU type (basic detection)
NVIDIA_DETECTED=false
if command -v nvidia-smi >/dev/null 2>&1 || [ -d "/proc/driver/nvidia" ] || lspci 2>/dev/null | grep -i nvidia >/dev/null 2>&1; then
    NVIDIA_DETECTED=true
    echo "Nvidia GPU detected."
fi

# GPU type detection and configuration
echo ""
echo "Are you using an Nvidia GPU or AMD/Intel GPU?"
echo "[1] AMD/Intel"
echo "[2] Nvidia"

while true; do
    if [ "$NVIDIA_DETECTED" = true ]; then
        read -p "Enter 1 or 2 (or press Enter for Nvidia): " gpu_choice
    else
        read -p "Enter 1 or 2 (or press Enter for AMD/Intel): " gpu_choice
    fi
    
    case "$gpu_choice" in
        ""|"1")
            # Default logic: if Nvidia detected, skip AMD/Intel unless explicitly chosen
            if [ "$gpu_choice" = "1" ] || [ "$NVIDIA_DETECTED" = false ]; then
                # AMD/Intel GPU - ask about DLSS usage
                echo ""
                echo "Will you try to use DLSS inputs? (enables spoofing, required for DLSS FG, Reflex->AL2)"
                echo "[1] Yes"
                echo "[2] No"
                
                while true; do
                    read -p "Enter 1 or 2 (or press Enter for Yes): " enabling_spoofing
                    
                    case "$enabling_spoofing" in
                        ""|"1")
                            # Keep spoofing enabled (default)
                            break
                            ;;
                        "2")
                            # Disable spoofing
                            config_file="OptiScaler.ini"
                            if [ ! -f "$config_file" ]; then
                                echo "Config file not found: $config_file"
                                read -p "Press Enter to continue..."
                            else
                                # Use sed to replace Dxgi=auto with Dxgi=false
                                sed -i 's/Dxgi=auto/Dxgi=false/g' "$config_file"
                                echo "Spoofing disabled in configuration."
                            fi
                            break
                            ;;
                        *)
                            echo "Invalid choice. Please enter 1 or 2."
                            continue
                            ;;
                    esac
                done
            fi
            break
            ;;
        "2")
            # Nvidia GPU - skip spoofing configuration
            break
            ;;
        *)
            echo "Invalid choice. Please enter 1 or 2."
            continue
            ;;
    esac
done

# Complete setup - rename OptiScaler file
echo ""
if [ "$overwrite_choice" = "y" ] || [ "$overwrite_choice" = "Y" ]; then
    echo "Removing previous $selected_filename..."
    rm -f "$selected_filename"
fi

echo "Renaming OptiScaler file to $selected_filename..."
if ! mv "$OPTISCALER_FILE" "$selected_filename"; then
    echo ""
    echo "ERROR: Failed to rename OptiScaler file to $selected_filename."
    echo "Please check file permissions and try again."
    read -p "Press Enter to exit..."
    exit 1
fi

# Create uninstaller
create_uninstaller() {
    cat > "remove_optiscaler.sh" << 'EOF'
#!/bin/bash

clear
echo " ::::::::  :::::::::  ::::::::::: :::::::::::  ::::::::   ::::::::      :::     :::        :::::::::: :::::::::  "
echo ":+:    :+: :+:    :+:     :+:         :+:     :+:    :+: :+:    :+:   :+: :+:   :+:        :+:        :+:    :+: "
echo "#+:    +:+ +:+    +:+     +:+         +:+     +:+        +:+         +:+   +:+  +:+        +:+        +:+    +:+ "
echo "+#+    +:+ +#++:++#+      +#+         +#+     +#++:++#++ +#+        +#++:++#++: +#+        +#++:++#   +#++:++#:  "
echo "+#+    +#+ +#+            +#+         +#+            +#+ +#+        +#+     +#+ +#+        +#+        +#+    +#+ "
echo "#+#    #+# #+#            #+#         #+#     #+#    #+# #+#    #+# #+#     #+# #+#        #+#        #+#    #+# "
echo " ########  ###            ###     ###########  ########   ########  ###     ### ########## ########## ###    ### "
echo ""
echo "Coping is strong with this one..."
echo ""

read -p "Do you want to remove OptiScaler? [y/n]: " remove_choice

if [ "$remove_choice" = "y" ] || [ "$remove_choice" = "Y" ]; then
    echo ""
    echo "Removing OptiScaler files..."
    
    # Remove OptiScaler files
    rm -f OptiScaler.log
    rm -f OptiScaler.ini
    rm -f SELECTED_FILENAME_PLACEHOLDER
    
    # Remove directories
    rm -rf D3D12_Optiscaler
    rm -rf DlssOverrides
    rm -rf Licenses
    
    echo ""
    echo "OptiScaler removed!"
    echo ""
    
    # Remove this uninstaller
    rm -f "$0"
else
    echo ""
    echo "Operation cancelled."
    echo ""
fi

read -p "Press Enter to exit..."
EOF

    # Replace the placeholder with the actual selected filename
    sed -i "s/SELECTED_FILENAME_PLACEHOLDER/$selected_filename/g" "remove_optiscaler.sh"
    
    # Make the uninstaller executable
    chmod +x "remove_optiscaler.sh"
    
    echo ""
    echo "Uninstaller created: remove_optiscaler.sh"
    echo ""
}

# Create the uninstaller
create_uninstaller

# Success message
clear
echo " OptiScaler setup completed successfully..."
echo ""
echo "  ___                 "
echo " (_         '        "
echo " /__  /)   /  () (/  "
echo "         _/      /    "
echo ""

# Display Wine DLL override information
echo "IMPORTANT FOR LINUX/WINE USERS:"
echo "You need to add the renamed DLL to Wine overrides:"
echo ""
echo "WINEDLLOVERRIDES=$selected_filename=n,b %COMMAND%"
echo ""
echo "For example, if using Steam, add this to launch options:"
echo "WINEDLLOVERRIDES=$selected_filename=n,b %command%"
echo ""
echo "Remember: Insert key opens OptiScaler overlay, Page Up/Down for performance stats"
echo ""
echo "Note: If you need to send log files for support, set LogLevel=0 and"
echo "LogToFile=true in OptiScaler.ini (forced debugging is disabled since 0.7.7-Pre8)"
echo ""
echo "IMPORTANT: Do not rename OptiScaler.ini - it must stay as OptiScaler.ini"
echo ""

SETUP_SUCCESS=true

# Cleanup - remove setup script
read -p "Press Enter to exit..."

if [ "$SETUP_SUCCESS" = true ]; then
    # Remove this setup script
    rm -f "$0"
fi

exit 0
