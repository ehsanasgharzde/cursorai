#!/bin/bash

# for debugging enable this:
# set -x

# --- ANSI Color Codes ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Global Variables ---
CURSOR_EXTRACT_DIR="/opt/Cursor"
ICON_PATH="/usr/share/pixmaps/cursor.png"
EXECUTABLE_PATH="${CURSOR_EXTRACT_DIR}/AppRun"
DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"
SYMLINK_PATH="/usr/local/bin/cursor"
REQUIRED_PACKAGES=("curl" "wget" "jq" "figlet" "rsync")
APPIMAGE_DEPENDENCIES=("bsdtar" "file" "grep" "xdg-utils" "desktop-file-utils")
USER_LOCAL_BIN="$HOME/.local/bin"
USER_DESKTOP_DIR="$HOME/.local/share/applications"
USER_ICON_DIR="$HOME/.local/share/icons"

# --- AppImage Integration Variables ---
APPIMAGE_INSTALL_DIR="$HOME/.local/bin"
APPIMAGE_DESKTOP_DIR="$HOME/.local/share/applications"
APPIMAGE_ICON_DIR="$HOME/.local/share/icons"
APPIMAGE_TEMP_DIR="/tmp/appimage_integration"

# --- Cursor Download Variables ---
CURSOR_API_BASE="https://www.cursor.com/api/download"
CURSOR_DOWNLOAD_BASE="https://downloads.cursor.com/production/client/linux"
CURSOR_ALT_DOWNLOAD="https://downloader.cursor.sh/linux/appImage"

# --- Architecture Detection ---
ARCH=$(uname -m)
case $ARCH in
    x86_64) CURSOR_ARCH="x64" ;;
    aarch64|arm64) CURSOR_ARCH="arm64" ;;
    *) CURSOR_ARCH="x64" ;;
esac

# --- Logging Functions ---
log_command() {
    local cmd="$1"
    local description="$2"
    
    print_info "Executing: $description"
    print_info "Command: $cmd"
    
    if [[ "$cmd" =~ ^safe_sudo ]]; then
        # Extract the actual command after safe_sudo
        local actual_cmd="${cmd#safe_sudo }"
        echo -e "${YELLOW}[SUDO] This command requires administrator privileges${RESET}"
        safe_sudo $actual_cmd
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            print_success "Command completed successfully"
        else
            print_error "Command failed with exit code $exit_code"
        fi
        return $exit_code
    else
        # Regular command execution
        eval "$cmd"
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            print_success "Command completed successfully"
        else
            print_error "Command failed with exit code $exit_code"
        fi
        return $exit_code
    fi
}

# --- Fixed Safe sudo execution ---
safe_sudo() {
    # Check if we can run sudo without password
    if sudo -n true 2>/dev/null; then
        print_info "Using cached sudo credentials"
        sudo "$@"
        return $?
    fi
    
    # Prompt for password if needed
    print_info "Administrator privileges required for: $*"
    echo -e "${YELLOW}Please enter your password:${RESET}"
    
    # Execute sudo command directly without timeout wrapper
    sudo "$@"
    local exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        print_error "Sudo command failed with exit code $exit_code"
        return $exit_code
    fi
    
    return 0
}

# --- Screen Clearing Function ---
clear_screen() {
    clear
    printf '\033[2J\033[H'
}

# --- Progress Bar Function ---
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r["
    printf '%*s' $completed | tr ' ' '='
    printf '%*s' $remaining | tr ' ' '-'
    printf "] %d%%" $percentage
}

# --- Download Progress Function ---
download_with_progress() {
    local url=$1
    local output=$2
    local description=$3
    
    print_info "$description"
    print_info "URL: $url"
    print_info "Output: $output"
    
    # Show wget progress
    wget --progress=bar:force --timeout=30 --tries=3 -O "$output" "$url" 2>&1 | \
    while IFS= read -r line; do
        echo "$line"
    done
    
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -eq 0 ]; then
        print_success "Download completed successfully"
    else
        print_error "Download failed with exit code $exit_code"
    fi
    
    return $exit_code
}

# --- Installation Progress Function ---
install_with_progress() {
    local packages=("$@")
    local total=${#packages[@]}
    local current=0
    
    for package in "${packages[@]}"; do
        current=$((current + 1))
        show_progress $current $total
        printf " Installing %s...\n" "$package"
        
        case $DISTRO_FAMILY in
            debian)
                log_command "safe_sudo apt-get install -y $package" "Installing $package via apt"
                ;;
            rhel)
                if command -v dnf &>/dev/null; then
                    log_command "safe_sudo dnf install -y $package" "Installing $package via dnf"
                else
                    log_command "safe_sudo yum install -y $package" "Installing $package via yum"
                fi
                ;;
            arch)
                log_command "safe_sudo pacman -S --noconfirm $package" "Installing $package via pacman"
                ;;
            suse)
                log_command "safe_sudo zypper install -y $package" "Installing $package via zypper"
                ;;
        esac
        
        show_progress $current $total
        printf " Installing %s... Done\n" "$package"
    done
    printf "\n"
}

# --- ASCII Art Display Function ---
display_cursor_logo() {
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
     ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
    ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
    ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
    ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
    ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
     ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝
                                                        
            █████╗ ██╗    ██╗██████╗ ███████╗           
           ██╔══██╗██║    ██║██╔══██╗██╔════╝           
           ███████║██║    ██║██║  ██║█████╗             
           ██╔══██║██║    ██║██║  ██║██╔══╝             
           ██║  ██║██║    ██║██████╔╝███████╗           
           ╚═╝  ╚═╝╚═╝    ╚═╝╚═════╝ ╚══════╝           
EOF
    echo -e "${RESET}"
    echo -e "${BOLD}${BLUE}         Advanced AI-Powered Code Editor${RESET}"
    echo -e "${CYAN}         Linux Installation & AppImage Integration Manager${RESET}"
    echo -e "${YELLOW}         Architecture: $ARCH ($CURSOR_ARCH)${RESET}"
    echo ""
}

# --- Print Colored Messages ---
print_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
}

print_error() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $1"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}[WARNING]${RESET} $1"
}

print_info() {
    echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"
}

print_step() {
    echo -e "${CYAN}${BOLD}[STEP]${RESET} $1"
}

# --- Wait for User Input ---
wait_for_input() {
    echo -e "${YELLOW}Press Enter to continue...${RESET}"
    read -r
}

# --- Help Function ---
show_help() {
    clear_screen
    display_cursor_logo
    echo -e "${BOLD}USAGE:${RESET}"
    echo "  ./cursor.sh [OPTIONS] [APPIMAGE_PATH]"
    echo ""
    echo -e "${BOLD}OPTIONS:${RESET}"
    echo "  --help                Display this help message"
    echo "  --install             Install Cursor IDE"
    echo "  --update              Update existing installation"
    echo "  --uninstall           Remove Cursor IDE"
    echo "  --integrate-appimage  Integrate an AppImage as desktop application"
    echo "  --list-appimages      List integrated AppImages"
    echo "  --remove-appimage     Remove an integrated AppImage"
    echo "  --check-version       Check latest available version"
    echo ""
    echo -e "${BOLD}APPIMAGE INTEGRATION:${RESET}"
    echo "  ./cursor.sh --integrate-appimage /path/to/app.AppImage"
    echo "  ./cursor.sh --integrate-appimage --auto-download"
    echo ""
    echo -e "${BOLD}INTERACTIVE MODE:${RESET}"
    echo "  Run without arguments for interactive menu"
    echo ""
    echo -e "${BOLD}EXAMPLES:${RESET}"
    echo "  ./cursor.sh                                    # Interactive installation"
    echo "  ./cursor.sh --install                          # Direct installation"
    echo "  ./cursor.sh --integrate-appimage app.AppImage  # Integrate AppImage"
    echo "  ./cursor.sh --check-version                    # Check latest version"
    echo "  ./cursor.sh --help                             # Show this help"
    echo ""
    wait_for_input
}

# --- Detect Linux Distribution ---
detect_distro() {
    print_step "Detecting Linux distribution..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_FAMILY=""
        
        case $DISTRO in
            ubuntu|debian|linuxmint|elementary|pop)
                DISTRO_FAMILY="debian"
                ;;
            fedora|rhel|centos|rocky|almalinux)
                DISTRO_FAMILY="rhel"
                ;;
            arch|manjaro|endeavouros|garuda)
                DISTRO_FAMILY="arch"
                ;;
            opensuse|suse)
                DISTRO_FAMILY="suse"
                ;;
            *)
                DISTRO_FAMILY="unknown"
                ;;
        esac
        
        print_info "Detected distribution: $PRETTY_NAME"
        print_info "Distribution family: $DISTRO_FAMILY"
        print_info "Architecture: $ARCH ($CURSOR_ARCH)"
    else
        print_error "Cannot detect Linux distribution"
        DISTRO_FAMILY="unknown"
    fi
}

# --- Check Latest Version ---
check_latest_version() {
    print_step "Checking latest Cursor version..."
    
    local api_urls=(
        "${CURSOR_API_BASE}?platform=linux-${CURSOR_ARCH}&releaseTrack=stable"
        "${CURSOR_API_BASE}?platform=linux-${CURSOR_ARCH}&releaseTrack=latest"
    )
    
    for release_track in "stable" "latest"; do
        local api_url="${CURSOR_API_BASE}?platform=linux-${CURSOR_ARCH}&releaseTrack=${release_track}"
        print_info "Checking $release_track release track..."
        print_info "API URL: $api_url"
        
        local response=$(curl -s -A "Mozilla/5.0 (X11; Linux x86_64)" "$api_url" 2>/dev/null)
        
        if [ -n "$response" ]; then
            local version=$(echo "$response" | jq -r '.version // .releaseVersion // empty' 2>/dev/null)
            local download_url=$(echo "$response" | jq -r '.downloadUrl // .url // empty' 2>/dev/null)
            
            if [ -n "$version" ] && [ "$version" != "null" ]; then
                print_success "Latest $release_track version: $version"
                if [ -n "$download_url" ] && [ "$download_url" != "null" ]; then
                    print_info "Download URL: $download_url"
                fi
                echo ""
            else
                print_warning "Could not parse version from $release_track API response"
            fi
        else
            print_warning "No response from $release_track API"
        fi
    done
}

# --- Create User Directories ---
create_user_directories() {
    print_step "Creating user directories..."
    
    local dirs=("$USER_LOCAL_BIN" "$USER_DESKTOP_DIR" "$USER_ICON_DIR" "$APPIMAGE_TEMP_DIR")
    
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_info "Creating directory: $dir"
            mkdir -p "$dir"
        else
            print_info "Directory already exists: $dir"
        fi
    done
    
    if [[ ":$PATH:" != *":$USER_LOCAL_BIN:"* ]]; then
        print_info "Adding $USER_LOCAL_BIN to PATH in ~/.bashrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    print_success "User directories created"
}

# --- Check AppImage Dependencies ---
check_appimage_dependencies() {
    print_step "Checking AppImage integration dependencies..."
    
    local missing_packages=()
    local all_packages=("${REQUIRED_PACKAGES[@]}" "${APPIMAGE_DEPENDENCIES[@]}")
    local total_packages=${#all_packages[@]}
    local current=0
    
    for package in "${all_packages[@]}"; do
        current=$((current + 1))
        show_progress $current $total_packages
        printf " Checking %s..." "$package"
        
        if ! command -v "$package" &>/dev/null; then
            printf " Missing\n"
            missing_packages+=("$package")
        else
            printf " Found\n"
        fi
    done
    printf "\n"
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        print_success "All dependencies are installed"
        return 0
    fi
    
    print_warning "Missing dependencies: ${missing_packages[*]}"
    show_dependency_install_commands "${missing_packages[@]}"
    
    read -p "Install missing dependencies automatically? [y/N]: " install_deps
    if [[ "$install_deps" =~ ^[Yy]$ ]]; then
        install_missing_dependencies "${missing_packages[@]}"
    else
        print_error "Please install missing dependencies manually"
        return 1
    fi
}

# --- Show Dependency Install Commands ---
show_dependency_install_commands() {
    local packages=("$@")
    print_info "To install missing dependencies manually:"
    
    case $DISTRO_FAMILY in
        debian)
            echo "  sudo apt-get update && sudo apt-get install -y ${packages[*]}"
            ;;
        rhel)
            if command -v dnf &>/dev/null; then
                echo "  sudo dnf install -y ${packages[*]}"
            else
                echo "  sudo yum install -y ${packages[*]}"
            fi
            ;;
        arch)
            echo "  sudo pacman -S --needed ${packages[*]}"
            ;;
        suse)
            echo "  sudo zypper install -y ${packages[*]}"
            ;;
        *)
            echo "  Please install these packages using your distribution's package manager"
            ;;
    esac
}

# --- Install Missing Dependencies ---
install_missing_dependencies() {
    local packages=("$@")
    
    print_step "Updating package database..."
    case $DISTRO_FAMILY in
        debian)
            log_command "safe_sudo apt-get update" "Updating apt package database"
            ;;
        rhel)
            if command -v dnf &>/dev/null; then
                log_command "safe_sudo dnf check-update" "Checking for dnf updates"
            fi
            ;;
        arch)
            log_command "safe_sudo pacman -Sy --noconfirm" "Updating pacman package database"
            ;;
        suse)
            log_command "safe_sudo zypper refresh" "Refreshing zypper repositories"
            ;;
    esac
    
    print_step "Installing missing packages..."
    install_with_progress "${packages[@]}"
    
    print_step "Verifying installation..."
    local still_missing=()
    for package in "${packages[@]}"; do
        if ! command -v "$package" &>/dev/null; then
            still_missing+=("$package")
        fi
    done
    
    if [ ${#still_missing[@]} -eq 0 ]; then
        print_success "All dependencies installed successfully"
        return 0
    else
        print_error "Some packages are still missing: ${still_missing[*]}"
        return 1
    fi
}

# --- Extract AppImage Metadata ---
extract_appimage_metadata() {
    local appimage_path="$1"
    local temp_dir="$APPIMAGE_TEMP_DIR/$(basename "$appimage_path" .AppImage)"
    
    print_step "Extracting AppImage metadata..."
    
    # Clean up any existing temp directory
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    
    # Make AppImage executable
    chmod +x "$appimage_path"
    
    # Extract AppImage contents
    print_info "Extracting AppImage contents..."
    cd "$temp_dir"
    "$appimage_path" --appimage-extract > /dev/null 2>&1
    
    if [ ! -d "$temp_dir/squashfs-root" ]; then
        print_error "Failed to extract AppImage"
        return 1
    fi
    
    # Find desktop file
    local desktop_file=""
    if [ -f "$temp_dir/squashfs-root/"*.desktop ]; then
        desktop_file=$(find "$temp_dir/squashfs-root/" -name "*.desktop" -type f | head -1)
    fi
    
    if [ -z "$desktop_file" ]; then
        print_warning "No desktop file found in AppImage"
        return 1
    fi
    
    # Extract information from desktop file
    local app_name=$(grep -i "^Name=" "$desktop_file" | cut -d= -f2- | head -1)
    local app_comment=$(grep -i "^Comment=" "$desktop_file" | cut -d= -f2- | head -1)
    local app_icon=$(grep -i "^Icon=" "$desktop_file" | cut -d= -f2- | head -1)
    local app_categories=$(grep -i "^Categories=" "$desktop_file" | cut -d= -f2- | head -1)
    
    # Find icon file
    local icon_file=""
    if [ -n "$app_icon" ]; then
        icon_file=$(find "$temp_dir/squashfs-root/" -name "*$app_icon*" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.xpm" \) | head -1)
    fi
    
    if [ -z "$icon_file" ]; then
        # Try to find any icon file
        icon_file=$(find "$temp_dir/squashfs-root/" -type f \( -name "*.png" -o -name "*.svg" -o -name "*.xpm" \) | head -1)
    fi
    
    # Export metadata
    export APPIMAGE_NAME="$app_name"
    export APPIMAGE_COMMENT="$app_comment"
    export APPIMAGE_ICON_FILE="$icon_file"
    export APPIMAGE_CATEGORIES="$app_categories"
    export APPIMAGE_TEMP_DIR="$temp_dir"
    
    print_success "AppImage metadata extracted successfully"
    print_info "Name: $app_name"
    print_info "Comment: $app_comment"
    print_info "Icon: $(basename "$icon_file" 2>/dev/null || echo "Not found")"
    
    return 0
}

# --- Check if AppImage Already Integrated ---
check_appimage_integration() {
    local appimage_path="$1"
    local appimage_basename=$(basename "$appimage_path")
    local appimage_name_clean=$(echo "$appimage_basename" | sed 's/\.AppImage$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
    
    # Check if desktop file exists
    local desktop_path="$USER_DESKTOP_DIR/${appimage_name_clean}.desktop"
    if [ -f "$desktop_path" ]; then
        print_warning "AppImage appears to be already integrated"
        print_info "Desktop file: $desktop_path"
        
        read -p "Re-integrate this AppImage? [y/N]: " reintegrate
        if [[ ! "$reintegrate" =~ ^[Yy]$ ]]; then
            print_info "Integration cancelled"
            return 1
        fi
    fi
    
    return 0
}

# --- Integrate AppImage ---
integrate_appimage() {
    local appimage_path="$1"
    
    if [ ! -f "$appimage_path" ]; then
        print_error "AppImage file not found: $appimage_path"
        return 1
    fi
    
    print_step "Integrating AppImage: $(basename "$appimage_path")"
    
    # Check if already integrated
    if ! check_appimage_integration "$appimage_path"; then
        return 1
    fi
    
    # Create user directories
    create_user_directories
    
    # Extract metadata
    if ! extract_appimage_metadata "$appimage_path"; then
        print_error "Failed to extract AppImage metadata"
        return 1
    fi
    
    # Generate names
    local appimage_basename=$(basename "$appimage_path")
    local appimage_name_clean=$(echo "$appimage_basename" | sed 's/\.AppImage$//' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
    local target_path="$USER_LOCAL_BIN/$appimage_basename"
    local desktop_path="$USER_DESKTOP_DIR/${appimage_name_clean}.desktop"
    local icon_path="$USER_ICON_DIR/${appimage_name_clean}.png"
    
    # Copy AppImage to user bin
    print_step "Installing AppImage to $USER_LOCAL_BIN..."
    print_info "Copying $appimage_path to $target_path"
    cp "$appimage_path" "$target_path"
    chmod +x "$target_path"
    
    # Copy icon if available
    if [ -n "$APPIMAGE_ICON_FILE" ] && [ -f "$APPIMAGE_ICON_FILE" ]; then
        print_step "Installing icon..."
        print_info "Copying icon to $icon_path"
        cp "$APPIMAGE_ICON_FILE" "$icon_path"
    fi
    
    # Create desktop file
    print_step "Creating desktop entry..."
    print_info "Creating desktop file: $desktop_path"
    cat > "$desktop_path" << EOF
[Desktop Entry]
Name=${APPIMAGE_NAME:-$(basename "$appimage_path" .AppImage)}
Comment=${APPIMAGE_COMMENT:-Integrated AppImage Application}
Exec=$target_path %F
Icon=${icon_path}
Type=Application
Categories=${APPIMAGE_CATEGORIES:-Utility;}
StartupNotify=true
Terminal=false
EOF
    
    chmod +x "$desktop_path"
    
    # Update desktop database
    print_step "Updating desktop database..."
    if command -v update-desktop-database &>/dev/null; then
        log_command "update-desktop-database '$USER_DESKTOP_DIR'" "Updating desktop database"
    fi
    
    # Clean up temporary directory
    print_step "Cleaning up temporary files..."
    rm -rf "$APPIMAGE_TEMP_DIR"
    
    print_success "AppImage integrated successfully!"
    print_info "Executable: $target_path"
    print_info "Desktop entry: $desktop_path"
    print_info "Icon: $icon_path"
    print_info "You can now find the application in your desktop environment's application menu"
    
    return 0
}

# --- List Integrated AppImages ---
list_integrated_appimages() {
    clear_screen
    display_cursor_logo
    
    print_step "Listing integrated AppImages..."
    
    if [ ! -d "$USER_DESKTOP_DIR" ]; then
        print_info "No integrated AppImages found"
        return 0
    fi
    
    local found_appimages=()
    local count=0
    
    for desktop_file in "$USER_DESKTOP_DIR"/*.desktop; do
        if [ -f "$desktop_file" ]; then
            local exec_line=$(grep "^Exec=" "$desktop_file" | cut -d= -f2-)
            if [[ "$exec_line" =~ \.AppImage ]]; then
                count=$((count + 1))
                local name=$(grep "^Name=" "$desktop_file" | cut -d= -f2-)
                local comment=$(grep "^Comment=" "$desktop_file" | cut -d= -f2-)
                
                echo "[$count] $name"
                echo "    Comment: $comment"
                echo "    Exec: $exec_line"
                echo "    Desktop file: $desktop_file"
                echo ""
                
                found_appimages+=("$desktop_file")
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_info "No integrated AppImages found"
    else
        print_success "Found $count integrated AppImage(s)"
    fi
    
    wait_for_input
}

# --- Remove Integrated AppImage ---
remove_integrated_appimage() {
    clear_screen
    display_cursor_logo
    
    print_step "Remove integrated AppImage..."
    
    if [ ! -d "$USER_DESKTOP_DIR" ]; then
        print_info "No integrated AppImages found"
        wait_for_input
        return 0
    fi
    
    local appimage_list=()
    local count=0
    
    # Build list of integrated AppImages
    for desktop_file in "$USER_DESKTOP_DIR"/*.desktop; do
        if [ -f "$desktop_file" ]; then
            local exec_line=$(grep "^Exec=" "$desktop_file" | cut -d= -f2- | awk '{print $1}')
            if [[ "$exec_line" =~ \.AppImage ]]; then
                count=$((count + 1))
                local name=$(grep "^Name=" "$desktop_file" | cut -d= -f2-)
                echo "[$count] $name"
                echo "    Exec: $exec_line"
                echo "    Desktop file: $desktop_file"
                echo ""
                
                appimage_list+=("$desktop_file|$exec_line")
            fi
        fi
    done
    
    if [ $count -eq 0 ]; then
        print_info "No integrated AppImages found"
        wait_for_input
        return 0
    fi
    
    read -p "Enter the number of the AppImage to remove [1-$count]: " selection
    
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$count" ]; then
        print_error "Invalid selection"
        wait_for_input
        return 1
    fi
    
    local selected_item="${appimage_list[$((selection - 1))]}"
    local desktop_file=$(echo "$selected_item" | cut -d'|' -f1)
    local exec_path=$(echo "$selected_item" | cut -d'|' -f2)
    local app_name=$(grep "^Name=" "$desktop_file" | cut -d= -f2-)
    
    print_warning "This will remove:"
    print_info "Application: $app_name"
    print_info "Desktop file: $desktop_file"
    print_info "Executable: $exec_path"
    
    read -p "Are you sure you want to remove this AppImage integration? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Removal cancelled"
        wait_for_input
        return 0
    fi
    
    # Remove files
    print_step "Removing AppImage integration..."
    
    # Remove desktop file
    print_info "Removing desktop file: $desktop_file"
    rm -f "$desktop_file"
    
    # Remove executable
    if [ -f "$exec_path" ]; then
        print_info "Removing executable: $exec_path"
        rm -f "$exec_path"
    fi
    
    # Remove icon (try to guess icon path)
    local icon_name=$(basename "$desktop_file" .desktop)
    local icon_path="$USER_ICON_DIR/${icon_name}.png"
    if [ -f "$icon_path" ]; then
        print_info "Removing icon: $icon_path"
        rm -f "$icon_path"
    fi
    
    # Update desktop database
    if command -v update-desktop-database &>/dev/null; then
        log_command "update-desktop-database '$USER_DESKTOP_DIR'" "Updating desktop database"
    fi
    
    print_success "AppImage integration removed successfully"
    wait_for_input
}

# --- Download Latest Cursor AppImage ---
download_latest_cursor_appimage() {
    print_step "Downloading latest Cursor AppImage..."
    
    # Try multiple API endpoints
    local api_urls=(
        "${CURSOR_API_BASE}?platform=linux-${CURSOR_ARCH}&releaseTrack=stable"
        "${CURSOR_API_BASE}?platform=linux-${CURSOR_ARCH}&releaseTrack=latest"
        "${CURSOR_ALT_DOWNLOAD}/${CURSOR_ARCH}"
    )
    
    local user_agent="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    local download_path="/tmp/cursor-latest.AppImage"
    local final_url=""
    
    # Try each API endpoint
    for api_url in "${api_urls[@]}"; do
        print_info "Trying API endpoint: $api_url"
        
        if [[ "$api_url" =~ "api/download" ]]; then
            # JSON API response
            local response=$(curl -s -A "$user_agent" "$api_url" 2>/dev/null)
            if [ -n "$response" ]; then
                final_url=$(echo "$response" | jq -r '.downloadUrl // .url // empty' 2>/dev/null)
                if [ -n "$final_url" ] && [ "$final_url" != "null" ]; then
                    print_success "Got download URL from API: $final_url"
                    break
                fi
            fi
        else
            # Direct download endpoint
            if curl -s -I -A "$user_agent" "$api_url" | grep -q "200 OK"; then
                final_url="$api_url"
                print_success "Direct download available: $final_url"
                break
            fi
        fi
    done
    
    if [ -z "$final_url" ]; then
        print_error "Could not retrieve download URL from any endpoint"
        return 1
    fi
    
    print_info "Final download URL: $final_url"
    
    # Download with progress
    if download_with_progress "$final_url" "$download_path" "Downloading Cursor AppImage..."; then
        if [ -s "$download_path" ]; then
            print_success "Download completed successfully"
            print_info "File size: $(du -h "$download_path" | cut -f1)"
            echo "$download_path"
            return 0
        else
            print_error "Downloaded file is empty"
            return 1
        fi
    else
        print_error "Download failed"
        return 1
    fi
}

# --- Launch Cursor Prompt ---
launch_cursor_prompt() {
    read -p "Launch Cursor IDE now? [y/N]: " launch_now
    if [[ "$launch_now" =~ ^[Yy]$ ]]; then
        print_info "Launching Cursor IDE..."
        if command -v cursor &>/dev/null; then
            cursor &
        elif [ -x "$EXECUTABLE_PATH" ]; then
            "$EXECUTABLE_PATH" &
        else
            print_error "Cursor executable not found"
        fi
    fi
}

# --- Install Cursor IDE ---
install_cursor() {
    clear_screen
    display_cursor_logo
    
    if [ -d "$CURSOR_EXTRACT_DIR" ]; then
        print_warning "Cursor IDE is already installed at $CURSOR_EXTRACT_DIR"
        echo "Use the update option to upgrade your installation."
        wait_for_input
        return 1
    fi
    
    if ! check_appimage_dependencies; then
        print_error "Failed to install required dependencies"
        wait_for_input
        return 1
    fi
    
    print_step "Choose installation method:"
    echo "  1. Download latest AppImage automatically (recommended)"
    echo "  2. Provide local AppImage path"
    echo "  3. Integrate as user AppImage (no system installation)"
    echo "  4. Try native package installation"
    echo "  5. Cancel installation"
    
    while true; do
        read -p "Enter your choice [1-5]: " choice
        case $choice in
            1)
                clear_screen
                display_cursor_logo
                local download_path
                download_path=$(download_latest_cursor_appimage)
                if [ $? -eq 0 ] && [ -f "$download_path" ]; then
                    install_appimage "$download_path"
                    launch_cursor_prompt
                    wait_for_input
                    return $?
                else
                    print_error "Download failed"
                    wait_for_input
                    return 1
                fi
                ;;
            2)
                read -p "Enter AppImage file path: " local_path
                if [ -f "$local_path" ]; then
                    clear_screen
                    display_cursor_logo
                    install_appimage "$local_path"
                    launch_cursor_prompt
                    wait_for_input
                    return $?
                else
                    print_error "File not found: $local_path"
                fi
                ;;
            3)
                clear_screen
                display_cursor_logo
                local download_path
                download_path=$(download_latest_cursor_appimage)
                if [ $? -eq 0 ] && [ -f "$download_path" ]; then
                    integrate_appimage "$download_path"
                    launch_cursor_prompt
                    wait_for_input
                    return $?
                else
                    print_error "Download failed"
                    wait_for_input
                    return 1
                fi
                ;;
            4)
                clear_screen
                display_cursor_logo
                if try_native_installation; then
                    print_success "Native installation completed successfully"
                    configure_desktop_integration
                    launch_cursor_prompt
                    wait_for_input
                    return 0
                else
                    print_error "Native installation failed"
                    wait_for_input
                    return 1
                fi
                ;;
            5)
                print_info "Installation cancelled"
                wait_for_input
                return 1
                ;;
            *)
                print_error "Invalid choice. Please enter 1, 2, 3, 4, or 5."
                ;;
        esac
    done
}

# --- Try Native Installation ---
try_native_installation() {
    print_info "Attempting native installation..."
    
    case $DISTRO_FAMILY in
        debian)
            try_debian_installation
            ;;
        rhel)
            try_rhel_installation
            ;;
        arch)
            try_arch_installation
            ;;
        *)
            print_warning "Native installation not available for $DISTRO_FAMILY"
            return 1
            ;;
    esac
}

# --- Debian-based Installation ---
try_debian_installation() {
    print_info "Attempting to install Cursor via .deb package..."
    
    # Try different download patterns
    local deb_urls=(
        "https://downloads.cursor.com/production/client/linux/${CURSOR_ARCH}/deb/cursor-latest.deb"
        "https://downloader.cursor.sh/linux/deb/${CURSOR_ARCH}"
    )
    
    local deb_path="/tmp/cursor.deb"
    local download_success=false
    
    for deb_url in "${deb_urls[@]}"; do
        print_info "Trying download from: $deb_url"
        
        if download_with_progress "$deb_url" "$deb_path" "Downloading .deb package..."; then
            if [ -s "$deb_path" ]; then
                download_success=true
                break
            fi
        fi
    done
    
    if [ "$download_success" = false ]; then
        print_error "Failed to download .deb package"
        return 1
    fi
    
    print_info "Installing .deb package..."
    
    if log_command "safe_sudo dpkg -i '$deb_path'" "Installing Cursor .deb package"; then
        # Fix any dependency issues
        log_command "safe_sudo apt-get install -f -y" "Fixing dependencies"
        print_success "Installed Cursor via .deb package"
        rm -f "$deb_path"
        return 0
    else
        print_error ".deb installation failed"
        rm -f "$deb_path"
        return 1
    fi
}

# --- RHEL-based Installation ---
try_rhel_installation() {
    print_info "Attempting to install Cursor via .rpm package..."
    
    # Try different download patterns
    local rpm_urls=(
        "https://downloads.cursor.com/production/client/linux/${CURSOR_ARCH}/rpm/cursor-latest.rpm"
        "https://downloader.cursor.sh/linux/rpm/${CURSOR_ARCH}"
    )
    
    local rpm_path="/tmp/cursor.rpm"
    local download_success=false
    
    for rpm_url in "${rpm_urls[@]}"; do
        print_info "Trying download from: $rpm_url"
        
        if download_with_progress "$rpm_url" "$rpm_path" "Downloading .rpm package..."; then
            if [ -s "$rpm_path" ]; then
                download_success=true
                break
            fi
        fi
    done
    
    if [ "$download_success" = false ]; then
        print_error "Failed to download .rpm package"
        return 1
    fi
    
    print_info "Installing .rpm package..."
    
    if command -v dnf &>/dev/null; then
        if log_command "safe_sudo dnf install -y '$rpm_path'" "Installing Cursor .rpm package via dnf"; then
            print_success "Installed Cursor via dnf"
            rm -f "$rpm_path"
            return 0
        fi
    elif command -v yum &>/dev/null; then
        if log_command "safe_sudo yum install -y '$rpm_path'" "Installing Cursor .rpm package via yum"; then
            print_success "Installed Cursor via yum"
            rm -f "$rpm_path"
            return 0
        fi
    fi
    
    print_error "RPM installation failed"
    rm -f "$rpm_path"
    return 1
}

# --- Arch-based Installation ---
try_arch_installation() {
    print_info "Attempting to install Cursor via AUR..."
    
    local aur_helpers=("yay" "paru" "aurman")
    local aur_packages=("cursor-appimage" "cursor-ide" "cursor-bin")
    
    for helper in "${aur_helpers[@]}"; do
        if command -v "$helper" &>/dev/null; then
            print_info "Using $helper to install from AUR..."
            
            for package in "${aur_packages[@]}"; do
                print_info "Trying AUR package: $package"
                
                if log_command "$helper -S --noconfirm $package" "Installing $package via $helper"; then
                    print_success "Installed Cursor via AUR ($helper - $package)"
                    return 0
                fi
            done
        fi
    done
    
    print_warning "No AUR helper found or AUR installation failed"
    return 1
}

# --- Install AppImage ---
install_appimage() {
    local appimage_path="$1"
    
    print_step "Installing Cursor from AppImage..."
    
    chmod +x "$appimage_path"
    
    print_info "Extracting AppImage..."
    cd /tmp
    "$appimage_path" --appimage-extract
    
    if [ ! -d "/tmp/squashfs-root" ]; then
        print_error "AppImage extraction failed"
        return 1
    fi
    
    print_info "Installing to system directory..."
    log_command "safe_sudo mkdir -p '$CURSOR_EXTRACT_DIR'" "Creating installation directory"
    
    # Use rsync with progress
    print_info "Copying files to $CURSOR_EXTRACT_DIR..."
    log_command "safe_sudo rsync -av --progress /tmp/squashfs-root/ '$CURSOR_EXTRACT_DIR/'" "Copying AppImage contents"
    
    if [ $? -eq 0 ]; then
        print_success "AppImage installed successfully"
        rm -rf /tmp/squashfs-root
        rm -f "$appimage_path"
        configure_desktop_integration
        return 0
    else
        print_error "Installation failed"
        rm -rf /tmp/squashfs-root
        return 1
    fi
}

# --- Configure Desktop Integration ---
configure_desktop_integration() {
    print_step "Configuring desktop integration..."
    
    print_info "Installing icon..."
    local icon_sources=(
        "${CURSOR_EXTRACT_DIR}/usr/share/icons/hicolor/128x128/apps/cursor.png"
        "${CURSOR_EXTRACT_DIR}/cursor.png"
        "${CURSOR_EXTRACT_DIR}/resources/app/assets/cursor.png"
    )
    
    for icon_source in "${icon_sources[@]}"; do
        if [ -f "$icon_source" ]; then
            print_info "Found icon at: $icon_source"
            log_command "safe_sudo cp '$icon_source' '$ICON_PATH'" "Installing icon"
            break
        fi
    done
    
    print_info "Creating desktop entry..."
    log_command "safe_sudo tee '$DESKTOP_ENTRY_PATH'" "Creating desktop entry" << EOF
[Desktop Entry]
Name=Cursor AI IDE
Comment=Advanced AI-powered code editor
Exec=${EXECUTABLE_PATH} --no-sandbox %F
Icon=cursor
Type=Application
Categories=Development;IDE;
MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java-source;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/x-ruby;text/x-sql;text/x-sh;
StartupNotify=true
StartupWMClass=Cursor
EOF
    
    print_info "Updating desktop database..."
    log_command "safe_sudo update-desktop-database" "Updating desktop database"
    
    print_info "Creating command line symlink..."
    log_command "safe_sudo ln -sf '$EXECUTABLE_PATH' '$SYMLINK_PATH'" "Creating command line symlink"
    
    print_success "Desktop integration configured"
    print_info "You can now run 'cursor' from the command line"
}

# --- Update Cursor ---
update_cursor() {
    clear_screen
    display_cursor_logo
    
    if [ ! -d "$CURSOR_EXTRACT_DIR" ]; then
        print_error "Cursor IDE is not installed"
        print_info "Use the install option to install Cursor first"
        wait_for_input
        return 1
    fi
    
    print_step "Updating Cursor IDE..."
    
    print_info "Creating backup of current installation..."
    log_command "safe_sudo cp -r '$CURSOR_EXTRACT_DIR' '${CURSOR_EXTRACT_DIR}.backup'" "Creating backup"
    
    if try_native_update; then
        print_success "Native update completed"
        log_command "safe_sudo rm -rf '${CURSOR_EXTRACT_DIR}.backup'" "Removing backup"
        launch_cursor_prompt
        wait_for_input
        return 0
    fi
    
    print_info "Updating via AppImage..."
    
    local download_path
    download_path=$(download_latest_cursor_appimage)
    if [ $? -eq 0 ] && [ -f "$download_path" ]; then
        print_info "Removing old installation..."
        log_command "safe_sudo rm -rf '${CURSOR_EXTRACT_DIR:?}'/*" "Removing old files"
        
        if install_appimage "$download_path"; then
            print_success "Update completed successfully"
            log_command "safe_sudo rm -rf '${CURSOR_EXTRACT_DIR}.backup'" "Removing backup"
            launch_cursor_prompt
            wait_for_input
            return 0
        else
            print_error "Update failed, restoring backup..."
            log_command "safe_sudo rm -rf '$CURSOR_EXTRACT_DIR'" "Removing failed installation"
            log_command "safe_sudo mv '${CURSOR_EXTRACT_DIR}.backup' '$CURSOR_EXTRACT_DIR'" "Restoring backup"
            wait_for_input
            return 1
        fi
    else
        print_error "Download failed, keeping current installation"
        log_command "safe_sudo rm -rf '${CURSOR_EXTRACT_DIR}.backup'" "Removing backup"
        wait_for_input
        return 1
    fi
}

# --- Try Native Update ---
try_native_update() {
    print_info "Attempting native update..."
    
    case $DISTRO_FAMILY in
        debian)
            log_command "safe_sudo apt-get update" "Updating package database"
            if log_command "safe_sudo apt-get upgrade -y cursor-ide" "Upgrading Cursor via apt"; then
                return 0
            fi
            ;;
        rhel)
            if command -v dnf &>/dev/null; then
                if log_command "safe_sudo dnf upgrade -y cursor-ide" "Upgrading Cursor via dnf"; then
                    return 0
                fi
            elif command -v yum &>/dev/null; then
                if log_command "safe_sudo yum update -y cursor-ide" "Upgrading Cursor via yum"; then
                    return 0
                fi
            fi
            ;;
        arch)
            if command -v yay &>/dev/null; then
                if log_command "yay -Syu --noconfirm cursor-appimage" "Upgrading Cursor via yay"; then
                    return 0
                fi
            elif command -v paru &>/dev/null; then
                if log_command "paru -Syu --noconfirm cursor-appimage" "Upgrading Cursor via paru"; then
                    return 0
                fi
            fi
            ;;
    esac
    return 1
}

# --- Uninstall Cursor ---
uninstall_cursor() {
    clear_screen
    display_cursor_logo
    
    print_warning "This will completely remove Cursor IDE from your system"
    echo "The following will be removed:"
    echo "  - Application files ($CURSOR_EXTRACT_DIR)"
    echo "  - Desktop entry ($DESKTOP_ENTRY_PATH)"
    echo "  - Icon file ($ICON_PATH)"
    echo "  - Command line symlink ($SYMLINK_PATH)"
    echo ""
    
    read -p "Are you sure you want to continue? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled"
        wait_for_input
        return 0
    fi
    
    print_step "Removing Cursor IDE..."
    
    local components=("$CURSOR_EXTRACT_DIR" "$DESKTOP_ENTRY_PATH" "$ICON_PATH" "$SYMLINK_PATH")
    local total=${#components[@]}
    local current=0
    
    for component in "${components[@]}"; do
        current=$((current + 1))
        show_progress $current $total
        
        if [[ "$component" == "$CURSOR_EXTRACT_DIR" ]] && [ -d "$component" ]; then
            printf " Removing application directory... "
            log_command "safe_sudo rm -rf '$component'" "Removing application directory"
            echo "Done"
        elif [ -f "$component" ] || [ -L "$component" ]; then
            printf " Removing %s... " "$(basename "$component")"
            log_command "safe_sudo rm -f '$component'" "Removing $(basename "$component")"
            echo "Done"
        else
            printf " Skipping %s (not found)... " "$(basename "$component")"
            echo "Done"
        fi
    done
    printf "\n"
    
    print_info "Updating desktop database..."
    log_command "safe_sudo update-desktop-database" "Updating desktop database"
    
    print_success "Cursor IDE has been successfully uninstalled"
    wait_for_input
}

# --- Main Menu ---
main_menu() {
    while true; do
        clear_screen
        display_cursor_logo
        
        echo -e "${BOLD}MAIN MENU${RESET}"
        echo "  1. Install Cursor IDE"
        echo "  2. Update Cursor IDE"
        echo "  3. Uninstall Cursor IDE"
        echo "  4. Check latest version"
        echo "  5. Integrate custom AppImage"
        echo "  6. List integrated AppImages"
        echo "  7. Remove integrated AppImage"
        echo "  8. Help"
        echo "  9. Exit"
        echo ""
        
        read -p "Enter your choice [1-9]: " choice
        
        case $choice in
            1) install_cursor ;;
            2) update_cursor ;;
            3) uninstall_cursor ;;
            4) check_latest_version; wait_for_input ;;
            5) 
                read -p "Enter AppImage path: " appimage_path
                if [ -f "$appimage_path" ]; then
                    integrate_appimage "$appimage_path"
                    wait_for_input
                else
                    print_error "File not found: $appimage_path"
                    wait_for_input
                fi
                ;;
            6) list_integrated_appimages ;;
            7) remove_integrated_appimage ;;
            8) show_help ;;
            9) 
                print_info "Goodbye!"
                exit 0
                ;;
            *) 
                print_error "Invalid choice. Please enter 1-9."
                sleep 2
                ;;
        esac
    done
}

# --- Main Script Logic ---
main() {
    # Enable debugging if requested
    if [[ "$1" == "--debug" ]]; then
        set -x
        shift
    fi
    
    # Detect distribution
    detect_distro
    
    # Process command line arguments
    case $1 in
        --help) show_help; exit 0 ;;
        --install) install_cursor; exit $? ;;
        --update) update_cursor; exit $? ;;
        --uninstall) uninstall_cursor; exit $? ;;
        --check-version) check_latest_version; exit $? ;;
        --integrate-appimage) 
            if [ -n "$2" ]; then
                integrate_appimage "$2"
                exit $?
            else
                print_error "AppImage path required"
                exit 1
            fi
            ;;
        --list-appimages) list_integrated_appimages; exit $? ;;
        --remove-appimage) remove_integrated_appimage; exit $? ;;
        --auto-download)
            download_path=$(download_latest_cursor_appimage)
            if [ $? -eq 0 ] && [ -f "$download_path" ]; then
                integrate_appimage "$download_path"
                exit $?
            else
                print_error "Download failed"
                exit 1
            fi
            ;;
        "")
            # Interactive mode
            main_menu
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
}

# --- Run Main Function ---
main "$@"
