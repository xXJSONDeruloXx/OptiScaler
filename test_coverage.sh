#!/bin/bash

# OptiScaler Setup Test Coverage Script
# This script automatically tests all user interaction paths for the setup script

# Configuration
OPTISCALER_SOURCE="/var/home/bazzite/Desktop/OptiScaler_v0.7.7-pre9_Daria"
SETUP_SCRIPT_SOURCE="/var/home/bazzite/dev/OptiScaler/optiscaler_setup.sh"
TEST_GAME_PATH="/var/home/bazzite/.local/share/Steam/steamapps/common/Expedition 33/Sandfall/Binaries/Win64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Log file
LOG_FILE="/tmp/optiscaler_test_$(date +%Y%m%d_%H%M%S).log"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${message}" >> "$LOG_FILE"
}

# Function to setup test environment
setup_test_env() {
    local test_name=$1
    print_status $BLUE "Setting up test environment for: $test_name"
    
    # Check if source directories exist
    if [ ! -d "$OPTISCALER_SOURCE" ]; then
        print_status $RED "ERROR: OptiScaler source directory not found: $OPTISCALER_SOURCE"
        return 1
    fi
    
    if [ ! -f "$SETUP_SCRIPT_SOURCE" ]; then
        print_status $RED "ERROR: Setup script not found: $SETUP_SCRIPT_SOURCE"
        return 1
    fi
    
    if [ ! -d "$TEST_GAME_PATH" ]; then
        print_status $RED "ERROR: Test game path not found: $TEST_GAME_PATH"
        return 1
    fi
    
    # Clean the test environment first
    cleanup_test_env
    
    # Copy OptiScaler files
    print_status $YELLOW "Copying OptiScaler files to test environment..."
    if ! cp -r "$OPTISCALER_SOURCE"/* "$TEST_GAME_PATH/"; then
        print_status $RED "Failed to copy OptiScaler files"
        return 1
    fi
    
    # Copy setup script
    print_status $YELLOW "Copying setup script to test environment..."
    if ! cp "$SETUP_SCRIPT_SOURCE" "$TEST_GAME_PATH/"; then
        print_status $RED "Failed to copy setup script"
        return 1
    fi
    
    # Make setup script executable
    chmod +x "$TEST_GAME_PATH/optiscaler_setup.sh"
    
    print_status $GREEN "Test environment setup complete"
    return 0
}

# Function to cleanup test environment
cleanup_test_env() {
    print_status $YELLOW "Cleaning test environment..."
    
    cd "$TEST_GAME_PATH" || return 1
    
    # Remove OptiScaler related files
    rm -f *.dll *.ini *.log *.sh *.bat 2>/dev/null
    rm -rf D3D12_Optiscaler DlssOverrides Licenses 2>/dev/null
    
    print_status $GREEN "Test environment cleaned"
}

# Function to run a test case
run_test_case() {
    local test_name=$1
    local responses=$2
    local expected_files=$3
    local description=$4
    
    print_status $CYAN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_status $CYAN "TEST: $test_name"
    print_status $CYAN "DESC: $description"
    print_status $CYAN "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    # Setup test environment
    if ! setup_test_env "$test_name"; then
        print_status $RED "FAILED: Could not setup test environment"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
    
    # Change to test directory
    cd "$TEST_GAME_PATH" || {
        print_status $RED "FAILED: Could not change to test directory"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    }
    
    # Run the setup script with automated responses
    print_status $YELLOW "Running setup script with responses: $responses"
    echo -e "$responses" | timeout 60s ./optiscaler_setup.sh &> "/tmp/test_output_${test_name}.log"
    local setup_exit_code=$?
    
    # Check if setup completed successfully
    if [ $setup_exit_code -eq 0 ]; then
        print_status $GREEN "Setup script completed successfully"
    elif [ $setup_exit_code -eq 124 ]; then
        print_status $RED "Setup script timed out"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    else
        print_status $YELLOW "Setup script exited with code: $setup_exit_code"
    fi
    
    # Check expected files
    print_status $YELLOW "Checking for expected files..."
    local test_passed=true
    
    # Special handling for installation cancelled test
    if [ "$test_name" = "install_cancelled" ]; then
        # For cancelled installation, we expect NO files to be created
        if [ -z "$expected_files" ]; then
            # Check that no OptiScaler files were created
            local unexpected_files=""
            for file in dxgi.dll winmm.dll version.dll dbghelp.dll d3d12.dll wininet.dll winhttp.dll OptiScaler.asi nvapi64.dll fakenvapi.ini nvngx.dll; do
                if [ -f "$file" ]; then
                    unexpected_files="$unexpected_files $file"
                fi
            done
            
            if [ -z "$unexpected_files" ]; then
                print_status $GREEN "✓ No files created (as expected for cancelled installation)"
            else
                print_status $RED "✗ Unexpected files created: $unexpected_files"
                test_passed=false
            fi
            
            # For cancelled installation, we don't expect an uninstaller
            if [ -f "remove_optiscaler.sh" ]; then
                print_status $RED "✗ Uninstaller created unexpectedly"
                test_passed=false
            else
                print_status $GREEN "✓ No uninstaller created (as expected)"
            fi
        fi
    else
        # Normal file checking for successful installations
        for file in $expected_files; do
            if [ -f "$file" ]; then
                print_status $GREEN "✓ Found expected file: $file"
            else
                print_status $RED "✗ Missing expected file: $file"
                test_passed=false
            fi
        done
        
        # Check for uninstaller
        if [ -f "remove_optiscaler.sh" ]; then
            print_status $GREEN "✓ Uninstaller created"
            
            # Test uninstaller
            print_status $YELLOW "Testing uninstaller..."
            echo "y" | ./remove_optiscaler.sh &> "/tmp/uninstall_output_${test_name}.log"
            
            # Check if files were removed
            local files_removed=true
            for file in $expected_files; do
                if [ -f "$file" ]; then
                    print_status $RED "✗ File not removed by uninstaller: $file"
                    files_removed=false
                fi
            done
            
            if [ "$files_removed" = true ]; then
                print_status $GREEN "✓ Uninstaller worked correctly"
            else
                print_status $RED "✗ Uninstaller failed to remove some files"
                test_passed=false
            fi
        else
            print_status $RED "✗ Uninstaller not created"
            test_passed=false
        fi
    fi
    
    # Record test result
    if [ "$test_passed" = true ]; then
        print_status $GREEN "PASSED: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_status $RED "FAILED: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        
        # Show last few lines of output for debugging
        print_status $YELLOW "Last 10 lines of setup output:"
        tail -10 "/tmp/test_output_${test_name}.log" | while read line; do
            print_status $YELLOW "  $line"
        done
    fi
    
    echo "" >> "$LOG_FILE"
    return 0
}

# Function to run all test cases
run_all_tests() {
    print_status $PURPLE "Starting OptiScaler Setup Test Coverage"
    print_status $PURPLE "Log file: $LOG_FILE"
    print_status $PURPLE "Test game path: $TEST_GAME_PATH"
    echo ""
    
    # Core Test Cases - Focus on important user decision paths
    
    # Test 1: Nvidia GPU (baseline)
    run_test_case "nvidia_default" \
        "y\n\n2\n" \
        "dxgi.dll OptiScaler.ini" \
        "Nvidia GPU - baseline test (no additional features)"
    
    # Test 2: AMD/Intel + DLSS Yes + FakeNVAPI Yes (full feature set)
    run_test_case "amd_dlss_yes_fakenvapi_yes" \
        "y\n\n1\n\n1\n" \
        "dxgi.dll OptiScaler.ini nvapi64.dll fakenvapi.ini nvngx.dll" \
        "AMD/Intel + DLSS enabled + FakeNVAPI yes (full feature installation)"
    
    # Test 3: AMD/Intel + DLSS Yes + FakeNVAPI No (nvngx only)
    run_test_case "amd_dlss_yes_fakenvapi_no" \
        "y\n\n1\n\n2\n" \
        "dxgi.dll OptiScaler.ini nvngx.dll" \
        "AMD/Intel + DLSS enabled + FakeNVAPI no (nvngx.dll only)"
    
    # Test 4: AMD/Intel + DLSS No + FakeNVAPI Yes (spoofing disabled)
    run_test_case "amd_dlss_no_fakenvapi_yes" \
        "y\n\n1\n2\n1\n" \
        "dxgi.dll OptiScaler.ini nvapi64.dll fakenvapi.ini" \
        "AMD/Intel + DLSS disabled + FakeNVAPI yes (no nvngx.dll, spoofing off)"
    
    # Test 5: AMD/Intel + DLSS No + FakeNVAPI No (minimal)
    run_test_case "amd_dlss_no_fakenvapi_no" \
        "y\n\n1\n2\n2\n" \
        "dxgi.dll OptiScaler.ini" \
        "AMD/Intel + DLSS disabled + FakeNVAPI no (minimal installation)"
    
    # Test 6: Installation cancelled
    run_test_case "install_cancelled" \
        "n\n" \
        "" \
        "Installation cancelled by user (should exit gracefully)"
    
    # Test 7: File overwrite scenario
    # First install something
    setup_test_env "overwrite_test_setup"
    cd "$TEST_GAME_PATH"
    echo -e "y\n\n2\n" | ./optiscaler_setup.sh &> /dev/null
    
    # Now test overwriting
    run_test_case "file_overwrite" \
        "y\ny\n\n2\n" \
        "dxgi.dll OptiScaler.ini" \
        "File overwrite scenario (existing dxgi.dll should be replaced)"
    
    # Test 8: AMD/Intel with auto-detected Nvidia (user override)
    run_test_case "nvidia_detected_amd_chosen" \
        "y\n\n1\n\n1\n" \
        "dxgi.dll OptiScaler.ini nvapi64.dll fakenvapi.ini nvngx.dll" \
        "Nvidia detected but user chooses AMD/Intel path (override detection)"
}

# Function to show test summary
show_test_summary() {
    echo ""
    print_status $PURPLE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_status $PURPLE "                           TEST SUMMARY"
    print_status $PURPLE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    print_status $CYAN "Total Tests: $TOTAL_TESTS"
    print_status $GREEN "Passed: $PASSED_TESTS"
    print_status $RED "Failed: $FAILED_TESTS"
    
    if [ $FAILED_TESTS -eq 0 ]; then
        print_status $GREEN "🎉 ALL TESTS PASSED! 🎉"
    else
        print_status $RED "❌ Some tests failed. Check the log for details."
    fi
    
    print_status $CYAN "Log file: $LOG_FILE"
    print_status $CYAN "Test outputs stored in: /tmp/test_output_*.log"
    print_status $PURPLE "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to check prerequisites
check_prerequisites() {
    print_status $YELLOW "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in timeout; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_status $RED "Missing required dependencies: ${missing_deps[*]}"
        print_status $RED "Please install them and try again"
        return 1
    fi
    
    # Check if paths exist
    if [ ! -d "$OPTISCALER_SOURCE" ]; then
        print_status $RED "OptiScaler source directory not found: $OPTISCALER_SOURCE"
        print_status $YELLOW "Please update OPTISCALER_SOURCE in the script"
        return 1
    fi
    
    if [ ! -f "$SETUP_SCRIPT_SOURCE" ]; then
        print_status $RED "Setup script not found: $SETUP_SCRIPT_SOURCE"
        return 1
    fi
    
    if [ ! -d "$TEST_GAME_PATH" ]; then
        print_status $RED "Test game path not found: $TEST_GAME_PATH"
        print_status $YELLOW "Please update TEST_GAME_PATH in the script or install the test game"
        return 1
    fi
    
    print_status $GREEN "All prerequisites met"
    return 0
}

# Main execution
main() {
    clear
    print_status $PURPLE "OptiScaler Setup Test Coverage Script"
    print_status $PURPLE "====================================="
    echo ""
    
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Ask for confirmation
    echo ""
    print_status $YELLOW "This script will:"
    print_status $YELLOW "1. Test multiple setup scenarios automatically"
    print_status $YELLOW "2. Copy files to and clean: $TEST_GAME_PATH"
    print_status $YELLOW "3. Run setup and uninstall scripts repeatedly"
    print_status $YELLOW "4. Generate detailed logs"
    echo ""
    
    read -p "Do you want to proceed? [y/N]: " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_status $YELLOW "Test cancelled by user"
        exit 0
    fi
    
    # Clean any existing test outputs
    rm -f /tmp/test_output_*.log /tmp/uninstall_output_*.log
    
    # Run all tests
    run_all_tests
    
    # Clean up final test environment
    cleanup_test_env
    
    # Show summary
    show_test_summary
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"
