# Cursor AI IDE Installer for Linux - Enhanced Edition

A comprehensive, robust, and user-friendly installer script for installing, updating, and managing the Cursor AI IDE on Linux systems. This enhanced version provides improved compatibility across major Linux distributions, fixes sudo authentication issues, and offers a professional command-line interface with dynamic feedback and versatile installation options.

---

## Introduction

**Cursor AI IDE** is an advanced AI-powered code editor that combines the familiar interface of VS Code with cutting-edge AI capabilities. This installer script provides a seamless way to install, update, and manage Cursor IDE on Linux systems, while also serving as a general-purpose AppImage integration tool.

### What's New in This Version

- **Fixed sudo authentication issues** - Resolves hanging password prompts and timeout problems
- **Enhanced error handling** - Better command execution tracking and failure recovery
- **Improved cross-distribution support** - Tested on Ubuntu, Fedora, Arch, and openSUSE
- **Professional CLI interface** - Clean, color-coded output without emojis
- **Robust AppImage integration** - Universal AppImage desktop integration system
- **Advanced dependency management** - Automatic detection and installation of required packages

---

## Features

### User Interface Improvements
- **ANSI Color-Formatted Output**: Professional color-coded messages and progress indicators
- **Dynamic Progress Bars**: Real-time feedback during downloads and installations
- **Interactive Menu System**: Beginner-friendly guided installation process
- **ASCII Art Logo**: Visually appealing Cursor IDE branding

### Enhanced Installation Methods
- **Native Package Installation**: Attempts system-native packages (`.deb`, `.rpm`, AUR) when available
- **AppImage Installation**: Downloads and installs the latest Cursor AppImage automatically
- **Local AppImage Support**: Install from pre-downloaded AppImage files
- **User-Space Integration**: Install without system privileges in `~/.local/`

### Cross-Distribution Support
- **APT** (Ubuntu, Debian, Linux Mint, Elementary OS)
- **DNF/YUM** (Fedora, CentOS, RHEL, Rocky Linux, AlmaLinux)
- **Pacman** (Arch Linux, Manjaro, EndeavourOS)
- **Zypper** (openSUSE, SLES)

### System Integration
- **Desktop Entry Creation**: Seamless integration with desktop environments
- **Icon Installation**: Proper application icons in system icon themes
- **Command-Line Access**: Creates `cursor` symlink for terminal usage
- **MIME Type Association**: Associates common file types with Cursor IDE

### Advanced Management Features
- **Safe Update System**: Automatic backup and rollback on update failure
- **Complete Uninstallation**: Clean removal of all files and configurations
- **AppImage Management**: Universal AppImage integration for any application
- **Dependency Verification**: Automatic checking and installation of required packages

---

## Prerequisites

The installer automatically detects and installs missing dependencies. Required packages include:

- `curl` - For downloading files and API requests
- `wget` - Alternative download method with progress bars
- `jq` - JSON parsing for API responses
- `figlet` - ASCII art generation (optional)
- `rsync` - Efficient file synchronization
- `bsdtar` - Archive extraction (AppImage integration)
- `file` - File type detection
- `xdg-utils` - Desktop integration utilities
- `desktop-file-utils` - Desktop entry management

---

## Installation

### Quick Install (Recommended)

```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/your-repo/cursor-installer/main/cursor.sh | bash

# Or download first, then run
wget https://raw.githubusercontent.com/your-repo/cursor-installer/main/cursor.sh
chmod +x cursor.sh
./cursor.sh
```

### Manual Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-repo/cursor-installer.git
   cd cursor-installer
   ```

2. **Make the script executable**:
   ```bash
   chmod +x cursor.sh
   ```

3. **Run the installer**:
   ```bash
   ./cursor.sh
   ```

---

## Usage

### Interactive Mode

Run the script without arguments to enter the interactive menu:

```bash
./cursor.sh
```

The interactive menu provides:
1. **Install Cursor IDE** - Choose from multiple installation methods
2. **Update Cursor IDE** - Safely update existing installation
3. **Uninstall Cursor IDE** - Completely remove Cursor IDE
4. **Check Latest Version** - Query latest available versions
5. **Integrate Custom AppImage** - Add any AppImage to desktop
6. **List Integrated AppImages** - Show all integrated AppImages
7. **Remove Integrated AppImage** - Remove specific AppImage integration
8. **Help** - Display usage information

### Command-Line Flags

For automation and scripting:

```bash
# Install Cursor IDE
./cursor.sh --install

# Update existing installation
./cursor.sh --update

# Uninstall Cursor IDE
./cursor.sh --uninstall

# Check latest version
./cursor.sh --check-version

# Integrate a custom AppImage
./cursor.sh --integrate-appimage /path/to/app.AppImage

# Auto-download and integrate Cursor AppImage
./cursor.sh --integrate-appimage --auto-download

# List integrated AppImages
./cursor.sh --list-appimages

# Remove integrated AppImage
./cursor.sh --remove-appimage

# Display help
./cursor.sh --help

# Enable debug mode
./cursor.sh --debug --install
```

---

## Code Structure and Architecture

### Core Components

#### 1. Configuration and Variables
```bash
# Global installation paths
CURSOR_EXTRACT_DIR="/opt/Cursor"
ICON_PATH="/usr/share/pixmaps/cursor.png"
DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"
SYMLINK_PATH="/usr/local/bin/cursor"

# User-specific paths
USER_LOCAL_BIN="$HOME/.local/bin"
USER_DESKTOP_DIR="$HOME/.local/share/applications"
USER_ICON_DIR="$HOME/.local/share/icons"
```

#### 2. Distribution Detection
```bash
detect_distro() {
    # Detects Linux distribution from /etc/os-release
    # Sets DISTRO_FAMILY for package manager selection
    # Supports debian, rhel, arch, suse families
}
```

#### 3. Fixed Sudo Authentication
```bash
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
```

#### 4. Installation Methods

**Native Package Installation**:
```bash
try_debian_installation() {
    # Downloads .deb package from official sources
    # Installs using dpkg with dependency resolution
}

try_rhel_installation() {
    # Downloads .rpm package
    # Installs using dnf/yum with dependency resolution
}

try_arch_installation() {
    # Uses AUR helpers (yay, paru) for installation
    # Tries multiple AUR packages (cursor-appimage, cursor-ide)
}
```

**AppImage Installation**:
```bash
install_appimage() {
    # Extracts AppImage to /opt/Cursor
    # Configures desktop integration
    # Creates command-line symlink
}
```

#### 5. AppImage Integration System
```bash
integrate_appimage() {
    # Universal AppImage integration for any application
    # Extracts metadata from embedded .desktop file
    # Creates user-space desktop integration
    # Handles icon extraction and installation
}
```

#### 6. Update and Maintenance
```bash
update_cursor() {
    # Creates backup of current installation
    # Attempts native update first
    # Falls back to AppImage update
    # Restores backup on failure
}
```

### Key Functions Overview

| Function | Purpose | Implementation Details |
|----------|---------|----------------------|
| `main()` | Entry point and argument parsing | Handles command-line flags and interactive mode |
| `detect_distro()` | Linux distribution detection | Uses `/etc/os-release` to determine package manager |
| `safe_sudo()` | Fixed sudo authentication | Resolves hanging password prompts |
| `install_cursor()` | Main installation orchestrator | Supports multiple installation methods |
| `integrate_appimage()` | AppImage desktop integration | Universal AppImage integration system |
| `update_cursor()` | Safe update mechanism | Backup and rollback support |
| `check_appimage_dependencies()` | Dependency management | Automatic package installation |
| `configure_desktop_integration()` | System integration | Desktop entries, icons, command-line access |

---

##  Technical Implementation

### Architecture Detection
```bash
ARCH=$(uname -m)
case $ARCH in
    x86_64) CURSOR_ARCH="x64" ;;
    aarch64|arm64) CURSOR_ARCH="arm64" ;;
    *) CURSOR_ARCH="x64" ;;
esac
```

### API Integration
The installer uses multiple API endpoints for resilience:
- `https://www.cursor.com/api/download` - Official API
- `https://downloads.cursor.com/production/client/linux` - Direct downloads
- `https://downloader.cursor.sh/linux/appImage` - Alternative endpoint

### Progress Tracking
```bash
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
```

### Error Handling
```bash
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
    fi
}
```

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Sudo Password Hanging
**Problem**: Script hangs after entering sudo password
**Solution**: This version fixes the issue by removing the timeout wrapper and using direct sudo execution.

#### 2. Permission Denied Errors
**Problem**: Cannot create directories or files
**Solution**: Ensure the script has proper permissions:
```bash
chmod +x cursor.sh
```

#### 3. Missing Dependencies
**Problem**: Required packages not found
**Solution**: Install manually if auto-installation fails:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install curl wget jq figlet rsync bsdtar file xdg-utils desktop-file-utils

# Fedora
sudo dnf install curl wget jq figlet rsync bsdtar file xdg-utils desktop-file-utils

# Arch Linux
sudo pacman -S curl wget jq figlet rsync bsdtar file xdg-utils desktop-file-utils
```

#### 4. Desktop Entry Not Appearing
**Problem**: Cursor doesn't appear in application menu
**Solution**: Update desktop database:
```bash
sudo update-desktop-database
```

#### 5. Command Not Found: cursor
**Problem**: `cursor` command not available in terminal
**Solution**: Verify symlink and PATH:
```bash
ls -la /usr/local/bin/cursor
echo $PATH
```

### Debug Mode
Enable debug mode for detailed execution tracing:
```bash
./cursor.sh --debug --install
```

---

## Contributing

We welcome contributions to improve the installer! Here's how to contribute:

### Development Setup
1. **Fork the repository**
2. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test thoroughly** on different distributions
5. **Submit a pull request**

### Code Style Guidelines
- Use consistent indentation (4 spaces)
- Add comments for complex logic
- Follow bash best practices
- Test on multiple Linux distributions
- Update documentation for new features

### Testing
Test the installer on various distributions:
- Ubuntu 20.04+, Debian 10+
- Fedora 35+, CentOS 8+
- Arch Linux, Manjaro
- openSUSE Leap 15.3+

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## Support

### Getting Help
- **GitHub Issues**: [Report bugs and request features](https://github.com/ehsanasgharzde/cursorai/issues)
- **GitHub Discussions**: [Community discussions and Q&A](https://github.com/ehsanasgharzde/cursorai/discussions)
- **Documentation**: This README and inline script comments

### Before Reporting Issues
1. Check existing issues and discussions
2. Run with debug mode: `./cursor.sh --debug`
3. Include system information:
   - Linux distribution and version
   - Architecture (x86_64, arm64)
   - Error messages and logs
   - Steps to reproduce

---

## Conclusion

The Cursor AI IDE Installer for Linux provides a comprehensive, reliable, and user-friendly solution for installing and managing Cursor IDE on Linux systems. With its fixed sudo authentication, enhanced error handling, cross-distribution support, and universal AppImage integration capabilities, it serves as both a specialized Cursor installer and a general-purpose AppImage management tool.

Whether you're a developer looking to quickly install Cursor IDE or a system administrator managing multiple Linux systems, this installer provides the flexibility, reliability, and features you need.

**Happy coding with Cursor AI IDE!**

---

*For the latest updates and releases, visit the [GitHub repository](https://github.com/ehsanasgharzde/cursorai).*
