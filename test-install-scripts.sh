#!/usr/bin/env bash
#
# Test suite for installation scripts
# Tests platform detection, binary URLs, and syntax
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASSED=0
FAILED=0

# Test result reporting
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

section() {
    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
}

# Test 1: Bash script syntax
test_bash_syntax() {
    section "Testing bash script syntax"

    if bash -n "$SCRIPT_DIR/install.sh" 2>/dev/null; then
        pass "install.sh has valid bash syntax"
    else
        fail "install.sh has syntax errors"
        return 1
    fi
}

# Test 2: PowerShell script existence
test_powershell_exists() {
    section "Testing PowerShell script"

    if [ -f "$SCRIPT_DIR/install.ps1" ]; then
        pass "install.ps1 exists"
    else
        fail "install.ps1 does not exist"
        return 1
    fi

    # Basic syntax check - look for common PowerShell patterns
    if grep -q "param(" "$SCRIPT_DIR/install.ps1" && \
       grep -q "function" "$SCRIPT_DIR/install.ps1"; then
        pass "install.ps1 has basic PowerShell structure"
    else
        fail "install.ps1 doesn't look like valid PowerShell"
        return 1
    fi
}

# Test 3: Windows platform detection in bash script
test_windows_detection() {
    section "Testing Windows platform detection"

    if grep -q "mingw.*msys.*cygwin" "$SCRIPT_DIR/install.sh"; then
        pass "Bash script detects Windows (MINGW/MSYS/Cygwin)"
    else
        fail "Bash script doesn't detect Windows environments"
        return 1
    fi

    if grep -q 'IS_WINDOWS=true' "$SCRIPT_DIR/install.sh"; then
        pass "Bash script sets IS_WINDOWS flag"
    else
        fail "Bash script doesn't set IS_WINDOWS flag"
        return 1
    fi
}

# Test 4: Binary download URLs
test_binary_urls() {
    section "Testing binary download URLs"

    # Check for Windows .exe download
    if grep -q "narsil-mcp-windows-x86_64.exe" "$SCRIPT_DIR/install.sh"; then
        pass "Bash script downloads Windows .exe"
    else
        fail "Bash script doesn't download Windows .exe"
        return 1
    fi

    # Check for tar.gz download for Unix
    if grep -q "tar.gz" "$SCRIPT_DIR/install.sh"; then
        pass "Bash script downloads tar.gz for Unix"
    else
        fail "Bash script doesn't download tar.gz for Unix"
        return 1
    fi

    # Check PowerShell downloads .exe
    if grep -q "narsil-mcp-windows.*\.exe" "$SCRIPT_DIR/install.ps1"; then
        pass "PowerShell script downloads .exe"
    else
        fail "PowerShell script doesn't download .exe"
        return 1
    fi
}

# Test 5: Check required sections in scripts
test_script_sections() {
    section "Testing required script sections"

    # Check bash script has required functions
    local required_functions=(
        "detect_platform"
        "install_binary"
        "install_from_source"
        "check_windows_compiler"
        "configure_ide"
    )

    for func in "${required_functions[@]}"; do
        if grep -q "${func}()" "$SCRIPT_DIR/install.sh"; then
            pass "install.sh has $func function"
        else
            fail "install.sh missing $func function"
        fi
    done

    # Check PowerShell script has required functions
    local required_ps_functions=(
        "Get-Architecture"
        "Install-Binary"
        "Install-FromSource"
        "Test-MSVCInstalled"
        "Add-ToPath"
    )

    for func in "${required_ps_functions[@]}"; do
        if grep -q "$func" "$SCRIPT_DIR/install.ps1"; then
            pass "install.ps1 has $func function"
        else
            fail "install.ps1 missing $func function"
        fi
    done
}

# Test 6: Windows-specific logic
test_windows_logic() {
    section "Testing Windows-specific logic"

    # Check bash script handles Windows binary extension
    if grep -q 'BINARY_NAME="narsil-mcp.exe"' "$SCRIPT_DIR/install.sh"; then
        pass "Bash script sets .exe extension for Windows"
    else
        fail "Bash script doesn't set .exe extension for Windows"
    fi

    # Check bash script uses Windows paths
    if grep -q 'LOCALAPPDATA' "$SCRIPT_DIR/install.sh"; then
        pass "Bash script uses LOCALAPPDATA for Windows"
    else
        fail "Bash script doesn't use LOCALAPPDATA for Windows"
    fi

    # Check bash script detects Windows Claude config
    if grep -q 'APPDATA/Claude' "$SCRIPT_DIR/install.sh"; then
        pass "Bash script checks Windows Claude config path"
    else
        fail "Bash script doesn't check Windows Claude config path"
    fi

    # Check PowerShell script uses correct paths
    if grep -q 'LOCALAPPDATA.*Programs.*narsil-mcp' "$SCRIPT_DIR/install.ps1"; then
        pass "PowerShell script uses correct install directory"
    else
        fail "PowerShell script doesn't use correct install directory"
    fi

    # Check PowerShell script checks for MSVC
    if grep -q 'Test-MSVCInstalled' "$SCRIPT_DIR/install.ps1"; then
        pass "PowerShell script checks for MSVC before source build"
    else
        fail "PowerShell script doesn't check for MSVC"
    fi
}

# Test 7: Documentation
test_documentation() {
    section "Testing documentation"

    if grep -q "irm.*install.ps1" "$SCRIPT_DIR/README.md"; then
        pass "README.md includes PowerShell install command"
    else
        fail "README.md missing PowerShell install command"
    fi

    if grep -q "Windows (PowerShell)" "$SCRIPT_DIR/README.md"; then
        pass "README.md has Windows section"
    else
        fail "README.md missing Windows section"
    fi

    if grep -q "Visual Studio Build Tools" "$SCRIPT_DIR/README.md"; then
        pass "README.md mentions VS Build Tools requirement"
    else
        fail "README.md doesn't mention VS Build Tools"
    fi
}

# Main test runner
main() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Installation Scripts Test Suite         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

    test_bash_syntax || true
    test_powershell_exists || true
    test_windows_detection || true
    test_binary_urls || true
    test_script_sections || true
    test_windows_logic || true
    test_documentation || true

    # Summary
    section "Test Summary"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    if [ $FAILED -gt 0 ]; then
        echo -e "${RED}Failed: $FAILED${NC}"
        echo ""
        echo -e "${YELLOW}Note: Some tests may fail on non-Windows systems.${NC}"
        echo -e "${YELLOW}This is expected as long as core functionality tests pass.${NC}"
        exit 1
    else
        echo -e "${GREEN}✨ All tests passed!${NC}"
        exit 0
    fi
}

main "$@"
