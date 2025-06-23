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

while true; do
    read -p "Do you want to install OptiScaler? [y/n]: " install_choice
    install_choice=$(echo "$install_choice" | tr -d ' ')
    if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
        break
    elif [ "$install_choice" = "n" ] || [ "$install_choice" = "N" ]; then
        echo "Installation cancelled."
        read -p "Press Enter to exit..."
        exit 0
    else
        echo "Please enter y or n."
    fi
done

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

# Function to download and install FakeNVAPI
install_fakenvapi() {
    echo ""
    echo "FakeNVAPI provides Reflex-to-AL2/LFX conversion for AMD/Intel GPUs."
    echo "This enables Anti-Lag 2 (RDNA cards) or Latency Flex support."
    echo ""
    echo "Would you like to download and install FakeNVAPI?"
    echo "[1] Yes - Download and install FakeNVAPI"
    echo "[2] No - Skip FakeNVAPI installation"
    
    while true; do
        read -p "Enter 1 or 2 (or press Enter for No): " fakenvapi_choice
        
        case "$fakenvapi_choice" in
            "1")
                echo ""
                echo "Downloading FakeNVAPI..."
                
                # Check if required tools are available
                if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
                    echo "ERROR: Neither wget nor curl is available. Please install one of them first."
                    echo "On most systems: sudo apt install wget  OR  sudo dnf install wget"
                    read -p "Press Enter to continue without FakeNVAPI..."
                    return 1
                fi
                
                if ! command -v unzip >/dev/null 2>&1; then
                    echo "ERROR: unzip is not available. Please install it first."
                    echo "On most systems: sudo apt install unzip  OR  sudo dnf install unzip"
                    read -p "Press Enter to continue without FakeNVAPI..."
                    return 1
                fi
                
                # Create temporary directory
                TEMP_DIR=$(mktemp -d)
                FAKENVAPI_URL="https://github.com/FakeMichau/fakenvapi/releases/download/v1.3.2/fakenvapi.zip"
                FAKENVAPI_ZIP="$TEMP_DIR/fakenvapi.zip"
                
                # Download FakeNVAPI
                echo "Downloading from: $FAKENVAPI_URL"
                if command -v wget >/dev/null 2>&1; then
                    if ! wget -O "$FAKENVAPI_ZIP" "$FAKENVAPI_URL"; then
                        echo "ERROR: Failed to download FakeNVAPI with wget."
                        rm -rf "$TEMP_DIR"
                        read -p "Press Enter to continue without FakeNVAPI..."
                        return 1
                    fi
                else
                    if ! curl -L -o "$FAKENVAPI_ZIP" "$FAKENVAPI_URL"; then
                        echo "ERROR: Failed to download FakeNVAPI with curl."
                        rm -rf "$TEMP_DIR"
                        read -p "Press Enter to continue without FakeNVAPI..."
                        return 1
                    fi
                fi
                
                # Extract FakeNVAPI
                echo "Extracting FakeNVAPI..."
                if ! unzip -q "$FAKENVAPI_ZIP" -d "$TEMP_DIR"; then
                    echo "ERROR: Failed to extract FakeNVAPI archive."
                    rm -rf "$TEMP_DIR"
                    read -p "Press Enter to continue without FakeNVAPI..."
                    return 1
                fi
                
                # Check if expected files exist
                if [ ! -f "$TEMP_DIR/nvapi64.dll" ] || [ ! -f "$TEMP_DIR/fakenvapi.ini" ]; then
                    echo "ERROR: Expected FakeNVAPI files not found in archive."
                    echo "Looking for: nvapi64.dll and fakenvapi.ini"
                    rm -rf "$TEMP_DIR"
                    read -p "Press Enter to continue without FakeNVAPI..."
                    return 1
                fi
                
                # Copy files to game directory
                echo "Installing FakeNVAPI files..."
                
                # Check for existing files and ask for overwrite
                files_exist=false
                if [ -f "nvapi64.dll" ]; then
                    echo "WARNING: nvapi64.dll already exists in the current folder."
                    files_exist=true
                fi
                if [ -f "fakenvapi.ini" ]; then
                    echo "WARNING: fakenvapi.ini already exists in the current folder."
                    files_exist=true
                fi
                
                if [ "$files_exist" = true ]; then
                    echo ""
                    while true; do
                        read -p "Do you want to overwrite existing FakeNVAPI files? [y/n]: " overwrite_fakenvapi
                        overwrite_fakenvapi=$(echo "$overwrite_fakenvapi" | tr -d ' ')
                        
                        if [ "$overwrite_fakenvapi" = "y" ] || [ "$overwrite_fakenvapi" = "Y" ]; then
                            break
                        elif [ "$overwrite_fakenvapi" = "n" ] || [ "$overwrite_fakenvapi" = "N" ]; then
                            echo "FakeNVAPI installation cancelled."
                            rm -rf "$TEMP_DIR"
                            return 1
                        fi
                    done
                fi
                
                # Copy the files
                if ! cp "$TEMP_DIR/nvapi64.dll" . || ! cp "$TEMP_DIR/fakenvapi.ini" .; then
                    echo "ERROR: Failed to copy FakeNVAPI files to game directory."
                    rm -rf "$TEMP_DIR"
                    read -p "Press Enter to continue without FakeNVAPI..."
                    return 1
                fi
                
                # Cleanup
                rm -rf "$TEMP_DIR"
                
                echo ""
                echo "FakeNVAPI installed successfully!"
                echo ""
                echo "IMPORTANT FakeNVAPI Information:"
                echo "- For Reflex-to-AL2/LFX conversion to work, Reflex must be enabled in game settings"
                echo "- DLSS-FG automatically enables Reflex"
                echo "- If the game doesn't expose Reflex, you can force it with force_reflex=2 in fakenvapi.ini"
                echo "- Anti-Lag 2 only supports RDNA cards and is Windows only"
                echo "- Latency Flex is cross-vendor and cross-platform"
                echo "- AL2 overlay shortcut: Alt+Shift+L"
                echo "- If you get low fps stutters with LFX, set force_reflex=1 in fakenvapi.ini"
                echo ""
                return 0
                ;;
            ""|"2")
                echo ""
                echo "Skipping FakeNVAPI installation."
                return 1
                ;;
            *)
                echo "Invalid choice. Please enter 1 or 2."
                continue
                ;;
        esac
    done
}

# Function to find and setup nvngx_dlss.dll for AMD/Intel users
setup_nvngx_dlss() {
    echo ""
    echo "Setting up nvngx_dlss.dll for AMD/Intel GPU compatibility..."
    echo ""
    
    # Check if nvngx.dll already exists
    if [ -f "nvngx.dll" ]; then
        echo "nvngx.dll already exists in the current folder."
        while true; do
            read -p "Do you want to overwrite the existing nvngx.dll? [y/n]: " overwrite_nvngx
            overwrite_nvngx=$(echo "$overwrite_nvngx" | tr -d ' ')
            
            if [ "$overwrite_nvngx" = "y" ] || [ "$overwrite_nvngx" = "Y" ]; then
                break
            elif [ "$overwrite_nvngx" = "n" ] || [ "$overwrite_nvngx" = "N" ]; then
                echo "Skipping nvngx.dll setup."
                return 0
            fi
        done
    fi
    
    # Step 3a: Try to find nvngx_dlss.dll locally (UE games)
    echo "Step 1: Searching for existing nvngx_dlss.dll file..."
    
    # Search patterns for nvngx_dlss.dll
    NVNGX_DLSS_FOUND=""
    
    # Check common locations relative to current directory
    SEARCH_PATHS=(
        "."
        "../.."
        "../../.."
        "../../../.."
        "../../../../.."
    )
    
    for base_path in "${SEARCH_PATHS[@]}"; do
        if [ -d "$base_path" ]; then
            # Look for nvngx_dlss.dll in Engine/Plugins subdirectories (UE games)
            if [ -d "$base_path/Engine/Plugins" ]; then
                echo "  Searching in $base_path/Engine/Plugins..."
                NVNGX_DLSS_FOUND=$(find "$base_path/Engine/Plugins" -name "nvngx_dlss.dll" -type f 2>/dev/null | head -1)
                if [ -n "$NVNGX_DLSS_FOUND" ]; then
                    break
                fi
            fi
            
            # Also search the base path and immediate subdirectories
            NVNGX_DLSS_FOUND=$(find "$base_path" -maxdepth 3 -name "nvngx_dlss.dll" -type f 2>/dev/null | head -1)
            if [ -n "$NVNGX_DLSS_FOUND" ]; then
                break
            fi
        fi
    done
    
    if [ -n "$NVNGX_DLSS_FOUND" ]; then
        echo "  Found nvngx_dlss.dll at: $NVNGX_DLSS_FOUND"
        echo "  Copying and renaming to nvngx.dll..."
        
        if cp "$NVNGX_DLSS_FOUND" "nvngx.dll"; then
            echo ""
            echo "✓ Successfully copied nvngx_dlss.dll to nvngx.dll"
            return 0
        else
            echo "  ERROR: Failed to copy nvngx_dlss.dll"
        fi
    else
        echo "  No local nvngx_dlss.dll found."
    fi
    
    # Step 3b: Download from Streamline SDK if local search failed
    echo ""
    echo "Step 2: Downloading nvngx_dlss.dll from NVIDIA Streamline SDK..."
    
    # Check if required tools are available
    if ! command -v wget >/dev/null 2>&1 && ! command -v curl >/dev/null 2>&1; then
        echo "ERROR: Neither wget nor curl is available for downloading."
        echo "Please install wget or curl and try again."
        echo "On most systems: sudo apt install wget  OR  sudo dnf install wget"
        manual_instruction
        return 1
    fi
    
    if ! command -v unzip >/dev/null 2>&1; then
        echo "ERROR: unzip is not available for extracting the SDK."
        echo "Please install unzip and try again."
        echo "On most systems: sudo apt install unzip  OR  sudo dnf install unzip"
        manual_instruction
        return 1
    fi
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    
    echo "  Getting latest Streamline SDK release info..."
    
    # Try to get the latest release info from GitHub API
    GITHUB_API_URL="https://api.github.com/repos/NVIDIA-RTX/Streamline/releases/latest"
    RELEASE_INFO="$TEMP_DIR/release_info.json"
    STREAMLINE_URL=""
    
    # Download release info
    if command -v wget >/dev/null 2>&1; then
        if wget -q -O "$RELEASE_INFO" "$GITHUB_API_URL" 2>/dev/null; then
            # Extract download URL from the JSON response
            STREAMLINE_URL=$(grep -o '"browser_download_url":[[:space:]]*"[^"]*streamline-sdk-[^"]*\.zip"' "$RELEASE_INFO" 2>/dev/null | sed 's/.*"browser_download_url":[[:space:]]*"//;s/".*//' | head -1)
        fi
    elif command -v curl >/dev/null 2>&1; then
        if curl -s -o "$RELEASE_INFO" "$GITHUB_API_URL" 2>/dev/null; then
            # Extract download URL from the JSON response
            STREAMLINE_URL=$(grep -o '"browser_download_url":[[:space:]]*"[^"]*streamline-sdk-[^"]*\.zip"' "$RELEASE_INFO" 2>/dev/null | sed 's/.*"browser_download_url":[[:space:]]*"//;s/".*//' | head -1)
        fi
    fi
    
    # Fallback URLs if API fails
    FALLBACK_URLS=(
        "https://github.com/NVIDIA-RTX/Streamline/releases/download/v2.8.0/streamline-sdk-v2.8.0.zip"
        "https://github.com/NVIDIA-RTX/Streamline/releases/download/v2.7.32/streamline-sdk-v2.7.32.zip"
        "https://github.com/NVIDIA-RTX/Streamline/releases/download/v2.7.31/streamline-sdk-v2.7.31.zip"
    )
    
    # If API failed or couldn't parse, use fallback URLs
    if [ -z "$STREAMLINE_URL" ]; then
        echo "  Could not get latest release info from API, trying known versions..."
        STREAMLINE_URL="${FALLBACK_URLS[0]}"
    fi
    
    STREAMLINE_ZIP="$TEMP_DIR/streamline-sdk.zip"
    
    echo "  Downloading from: $STREAMLINE_URL"
    
    # Try to download Streamline SDK with fallbacks
    DOWNLOAD_SUCCESS=false
    URLS_TO_TRY=("$STREAMLINE_URL")
    
    # If the first URL isn't from our fallback list, add fallbacks
    if [[ ! " ${FALLBACK_URLS[@]} " =~ " ${STREAMLINE_URL} " ]]; then
        URLS_TO_TRY+=("${FALLBACK_URLS[@]}")
    fi
    
    for url in "${URLS_TO_TRY[@]}"; do
        echo "  Trying: $url"
        
        if command -v wget >/dev/null 2>&1; then
            if wget --progress=dot:giga -O "$STREAMLINE_ZIP" "$url" 2>/dev/null; then
                DOWNLOAD_SUCCESS=true
                break
            fi
        else
            if curl -L --progress-bar -o "$STREAMLINE_ZIP" "$url" 2>/dev/null; then
                DOWNLOAD_SUCCESS=true
                break
            fi
        fi
        
        echo "  Failed to download from: $url"
        
        # Don't try more URLs if this was the last one
        if [ "$url" != "${URLS_TO_TRY[-1]}" ]; then
            echo "  Trying next URL..."
        fi
    done
    
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        rm -rf "$TEMP_DIR"
        echo ""
        echo "  All download attempts failed. This could be due to:"
        echo "  - Network connectivity issues"
        echo "  - GitHub servers being unavailable"
        echo "  - Release URLs may have changed"
        echo ""
        echo "  You can try downloading manually from:"
        echo "  https://github.com/NVIDIA-RTX/Streamline/releases/latest"
        echo "  Look for 'streamline-sdk-*.zip' file"
        manual_instruction
        return 1
    fi
    
    echo "  Extracting Streamline SDK..."
    if ! unzip -q "$STREAMLINE_ZIP" -d "$TEMP_DIR" 2>/dev/null; then
        echo "  ERROR: Failed to extract Streamline SDK archive."
        rm -rf "$TEMP_DIR"
        manual_instruction
        return 1
    fi
    
    # Search for nvngx_dlss.dll in the extracted SDK
    NVNGX_DLSS_SDK=$(find "$TEMP_DIR" -name "nvngx_dlss.dll" -type f 2>/dev/null | head -1)
    
    if [ -z "$NVNGX_DLSS_SDK" ]; then
        echo "  ERROR: nvngx_dlss.dll not found in Streamline SDK archive."
        rm -rf "$TEMP_DIR"
        manual_instruction
        return 1
    fi
    
    echo "  Found nvngx_dlss.dll in SDK, copying and renaming to nvngx.dll..."
    
    if cp "$NVNGX_DLSS_SDK" "nvngx.dll"; then
        echo ""
        echo "✓ Successfully downloaded and installed nvngx_dlss.dll as nvngx.dll"
        rm -rf "$TEMP_DIR"
        return 0
    else
        echo "  ERROR: Failed to copy nvngx_dlss.dll from SDK."
        rm -rf "$TEMP_DIR"
        manual_instruction
        return 1
    fi
}

# Function to provide manual instructions if automatic setup fails
manual_instruction() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                        MANUAL SETUP REQUIRED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "To enable DLSS features on AMD/Intel GPUs, you need nvngx_dlss.dll."
    echo "Please choose one of the following options:"
    echo ""
    echo "📁 OPTION A - Find locally (for Unreal Engine games):"
    echo "   1. Navigate to your game's root folder"
    echo "   2. Look for nvngx_dlss.dll in Engine/Plugins subdirectories"
    echo "   3. Copy the file to this folder (where OptiScaler is installed)"
    echo "   4. Rename it to: nvngx.dll"
    echo ""
    echo "🌐 OPTION B - Download manually:"
    echo "   1. Visit: https://github.com/NVIDIA-RTX/Streamline/releases/latest"
    echo "   2. Download the 'streamline-sdk-*.zip' file"
    echo "   3. Extract and find nvngx_dlss.dll inside"
    echo "   4. Copy it to this folder and rename to: nvngx.dll"
    echo ""
    echo "   Alternative download sources:"
    echo "   - TechPowerUp GPU database"
    echo "   - NVIDIA Developer website"
    echo ""
    echo "⏭️  OPTION C - Skip (recommended if unsure):"
    echo "   OptiScaler will try to find nvngx_dlss.dll automatically at runtime."
    echo "   You can always add it later if needed."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    read -p "Press Enter when you've completed manual setup or want to skip..."
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
                            echo "Spoofing enabled - DLSS features will be available."
                            
                            # Offer FakeNVAPI installation for AMD/Intel users
                            install_fakenvapi
                            
                            # Setup nvngx_dlss.dll for AMD/Intel users (only when spoofing enabled)
                            setup_nvngx_dlss
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
                                echo "Note: DLSS features will not be available, so nvngx_dlss.dll setup is skipped."
                            fi
                            
                            # Still offer FakeNVAPI for AMD/Intel users even without spoofing
                            # (can still be useful for some scenarios)
                            install_fakenvapi
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
    rm -f "OptiScaler Setup.bat"
    rm -f SELECTED_FILENAME_PLACEHOLDER
    
    # Remove FakeNVAPI files if they exist
    if [ -f "nvapi64.dll" ] || [ -f "fakenvapi.ini" ]; then
        echo "Removing FakeNVAPI files..."
        rm -f nvapi64.dll
        rm -f fakenvapi.ini
    fi
    
    # Remove nvngx.dll if it exists
    if [ -f "nvngx.dll" ]; then
        echo "Removing nvngx.dll..."
        rm -f nvngx.dll
    fi
    
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
