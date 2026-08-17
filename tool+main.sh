#!/bin/bash

# Check if running with bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script must be run with bash, not sh or dash." >&2
    echo "Please use: bash $0" >&2
    exit 1
fi

# ============================================
# ADVANCED ZIP PASSWORD CRACKER WITH MULTI-FORMAT
# AND PERSONAL INFORMATION ATTACK
# ============================================

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Global Variables
CURRENT_FILE=""
PASSWORD_LENGTH=0
PATTERN=""
CHARSET=""
ATTACK_MODE=""
DICT_FILE=""
OUTPUT_DIR="extracted"
PYTHON_CRACKER="advanced+cracker.py"
ZIP_TYPE="standard"
DICT_TYPE="default"

# ============================================
# DISPLAY FUNCTIONS
# ============================================

clear_screen() {
    clear
}

print_header() {
    local title="$1"
    echo ""
    echo -e "${PURPLE}╭───────────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│${NC}${WHITE}        $title${NC}"
    echo -e "${PURPLE}╰───────────────────────────────────────────────╯${NC}"
    echo ""
}

print_prompt() {
    echo -e "${CYAN}►${NC} ${WHITE}$1${NC}"
}

print_choice() {
    echo -e "${GREEN}$1.${NC} ${WHITE}$2${NC}"
}

print_error() {
    echo -e "${RED}[!]${NC} ${WHITE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} ${WHITE}$1${NC}"
}

print_info() {
    echo -e "${BLUE}[*]${NC} ${WHITE}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} ${WHITE}$1${NC}"
}

print_line() {
    echo -e "${BLUE}────────────────────────────────────────────────${NC}"
}

# ============================================
# REQUIREMENT CHECK
# ============================================

check_requirements() {
    print_info "Checking requirements..."
    
    local need_pyzipper=0
    local need_rarfile=0
    local need_py7zr=0
    local need_python=0
    local need_pip=0
    local need_unrar=0
    local need_7z=0
    local need_pypdf2=0
    local need_openpyxl=0
    local need_pptx=0
    local need_docx=0
    local need_xlrd=0
    
    if ! command -v python3 &> /dev/null; then
        print_warning "Python3 not found!"
        need_python=1
    else
        print_success "Python3: $(python3 --version 2>&1)"
    fi
    
    if ! command -v pip3 &> /dev/null; then
        print_warning "pip3 not found!"
        need_pip=1
    else
        print_success "pip3: $(pip3 --version 2>&1 | head -n1)"
    fi
    
    if ! python3 -c "import pyzipper" 2>/dev/null; then
        print_warning "pyzipper module not found (for AES encryption)"
        need_pyzipper=1
    else
        print_success "pyzipper: OK"
    fi
    
    if ! python3 -c "import rarfile" 2>/dev/null; then
        print_info "rarfile module not found (optional, for RAR support)"
        need_rarfile=1
    else
        print_success "rarfile: OK"
    fi
    
    if ! command -v unrar &> /dev/null; then
        print_info "unrar not found (optional, for RAR support)"
        need_unrar=1
    else
        print_success "unrar: OK"
    fi
    
    if ! python3 -c "import py7zr" 2>/dev/null; then
        print_info "py7zr module not found (optional, for 7Z support)"
        need_py7zr=1
    else
        print_success "py7zr: OK"
    fi
    
    if ! command -v 7z &> /dev/null; then
        print_info "7z not found (optional, for 7Z support)"
        need_7z=1
    else
        print_success "7z: OK"
    fi
    
    # PDF support
    if ! python3 -c "import PyPDF2" 2>/dev/null; then
        print_info "PyPDF2 module not found (for PDF support)"
        need_pypdf2=1
    else
        print_success "PyPDF2: OK"
    fi
    
    # Excel support
    if ! python3 -c "import openpyxl" 2>/dev/null; then
        print_info "openpyxl module not found (for Excel XLSX support)"
        need_openpyxl=1
    else
        print_success "openpyxl: OK"
    fi
    
    if ! python3 -c "import xlrd" 2>/dev/null; then
        print_info "xlrd module not found (for Excel XLS support)"
        need_xlrd=1
    else
        print_success "xlrd: OK"
    fi
    
    # PowerPoint support
    if ! python3 -c "from pptx import Presentation" 2>/dev/null; then
        print_info "python-pptx module not found (for PowerPoint support)"
        need_pptx=1
    else
        print_success "python-pptx: OK"
    fi
    
    # Word support
    if ! python3 -c "import docx" 2>/dev/null; then
        print_info "python-docx module not found (for Word support)"
        need_docx=1
    else
        print_success "python-docx: OK"
    fi
    
    echo ""
    
    if [[ $need_python -eq 1 ]]; then
        print_info "Installing Python3..."
        pkg install python3 -y
    fi
    
    if [[ $need_pip -eq 1 ]]; then
        print_info "Installing pip3..."
        pkg install python3-pip -y
    fi
    
    if [[ $need_pyzipper -eq 1 ]]; then
        print_info "Installing pyzipper (required)..."
        pip3 install pyzipper
    fi
    
    echo ""
    echo -e "${CYAN}Install optional modules for RAR/7Z/PDF/Office support? (y/n):${NC}"
    read install_optional
    
    if [[ "$install_optional" =~ ^[Yy]$ ]]; then
        if [[ $need_rarfile -eq 1 ]]; then
            print_info "Installing rarfile (for RAR)..."
            pip3 install rarfile
        fi
        
        if [[ $need_unrar -eq 1 ]]; then
            print_info "Installing unrar (for RAR extraction)..."
            pkg install unrar -y
        fi
        
        if [[ $need_py7zr -eq 1 ]]; then
            print_info "Installing py7zr (for 7Z)..."
            pip3 install py7zr
        fi
        
        if [[ $need_7z -eq 1 ]]; then
            print_info "Installing 7z (for 7Z extraction)..."
            pkg install p7zip -y
        fi
        
        if [[ $need_pypdf2 -eq 1 ]]; then
            print_info "Installing PyPDF2 (for PDF)..."
            pip3 install PyPDF2
        fi
        
        if [[ $need_openpyxl -eq 1 ]]; then
            print_info "Installing openpyxl (for Excel XLSX)..."
            pip3 install openpyxl
        fi
        
        if [[ $need_xlrd -eq 1 ]]; then
            print_info "Installing xlrd (for Excel XLS)..."
            pip3 install xlrd
        fi
        
        if [[ $need_pptx -eq 1 ]]; then
            print_info "Installing python-pptx (for PowerPoint)..."
            pip3 install python-pptx
        fi
        
        if [[ $need_docx -eq 1 ]]; then
            print_info "Installing python-docx (for Word)..."
            pip3 install python-docx
        fi
    else
        print_info "Skipping optional modules"
    fi
    
    print_success "Requirements check completed"
    sleep 1
}

# ============================================
# STEP 1: FILE SELECTION
# ============================================

select_file() {
    while true; do
        clear_screen
        print_header "File Selection"
        
        print_prompt "Please enter the file location"
        echo -e "${CYAN}Enter file path:${NC}"
        read -e file_path
        
        file_path="${file_path//\'/}"
        file_path="${file_path//\"/}"
        file_path="${file_path/#\~/$HOME}"
        
        if [[ -z "$file_path" ]]; then
            print_error "No file path provided"
            echo ""
            echo -e "${YELLOW}Press Enter to try again...${NC}"
            read
            continue
        fi
        
        if [[ ! -f "$file_path" ]];then
            print_error "File not found: $file_path"
            echo ""
            echo -e "${CYAN}Current directory:${NC} $(pwd)"
            echo -e "${CYAN}Files available:${NC}"
            ls -la | head -10
            echo ""
            echo -e "${YELLOW}Press Enter to try again...${NC}"
            read
            continue
        fi
        
        local file_size=$(du -h "$file_path" 2>/dev/null | cut -f1)
        local file_type=$(file -b "$file_path" 2>/dev/null || echo "Unknown")
        
        echo ""
        print_line
        echo -e "${GREEN}File Information:${NC}"
        echo -e "${CYAN}Name:${NC} ${WHITE}$(basename "$file_path")${NC}"
        echo -e "${CYAN}Size:${NC} ${WHITE}$file_size${NC}"
        echo -e "${CYAN}Type:${NC} ${WHITE}$file_type${NC}"
        print_line
        
        echo ""
        echo -e "${CYAN}Use this file? (y/n):${NC}"
        read confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            CURRENT_FILE="$file_path"
            return 0
        fi
    done
}

# ============================================
# STEP 1A: FILE TYPE SELECTION
# ============================================

select_file_type() {
    clear_screen
    print_header "Select File Type"
    
    echo -e "${WHITE}Choose file format:${NC}"
    echo ""
    
    print_choice "1" "Standard ZIP (zipcrypt)"
    print_choice "2" "AES Encrypted ZIP (WinZip, 7-Zip AES)"
    print_choice "3" "7Z Archive (7-Zip format)"
    print_choice "4" "RAR Archive (WinRAR)"
    print_choice "5" "PDF Document (Adobe PDF)"
    print_choice "6" "Excel File (XLS/XLSX)"
    print_choice "7" "PowerPoint File (PPT/PPTX)"
    print_choice "8" "Word Document (DOC/DOCX)"
    print_choice "9" "Auto Detect (Recommended)"
    echo ""
    
    while true; do
        echo -e "${CYAN}Select option [1-9]:${NC}"
        read choice
        
        case $choice in
            1) ZIP_TYPE="standard"; break ;;
            2) ZIP_TYPE="aes"; break ;;
            3) 
                if ! command -v 7z &> /dev/null; then
                    print_warning "7z command not found"
                    echo -e "${CYAN}Install p7zip? (y/n):${NC}"
                    read install7z
                    if [[ "$install7z" =~ ^[Yy]$ ]]; then
                        pkg install p7zip -y
                    fi
                fi
                ZIP_TYPE="7z"
                break
                ;;
            4)
                if ! command -v unrar &> /dev/null; then
                    print_warning "unrar command not found"
                    echo -e "${CYAN}Install unrar? (y/n):${NC}"
                    read installunrar
                    if [[ "$installunrar" =~ ^[Yy]$ ]]; then
                        pkg install unrar -y
                    fi
                fi
                ZIP_TYPE="rar"
                break
                ;;
            5) ZIP_TYPE="pdf"; break ;;
            6) ZIP_TYPE="excel"; break ;;
            7) ZIP_TYPE="powerpoint"; break ;;
            8) ZIP_TYPE="word"; break ;;
            9) ZIP_TYPE="auto"; break ;;
            *) print_error "Invalid choice" ;;
        esac
    done
    
    print_success "Selected: $ZIP_TYPE mode"
    sleep 1
}

# ============================================
# STEP 2: ATTACK MODE SELECTION
# ============================================

select_attack_mode() {
    clear_screen
    print_header "Select Attack Mode"
    
    echo -e "${WHITE}Choose attack method:${NC}"
    echo ""
    
    print_choice "1" "Brute Force Attack (Pattern based)"
    print_choice "2" "Dictionary Attack (Password list)"
    print_choice "3" "Smart Dictionary Attack (Advanced)"
    print_choice "4" "Personal Information Attack"
    print_choice "5" "Test Single Password"
    echo ""
    
    while true; do
        echo -e "${CYAN}Select option [1-5]:${NC}"
        read choice
        
        case $choice in
            1) ATTACK_MODE="bruteforce"; break ;;
            2) ATTACK_MODE="dictionary"; break ;;
            3) ATTACK_MODE="smartdict"; break ;;
            4) ATTACK_MODE="personal"; break ;;
            5) ATTACK_MODE="single"; break ;;
            *) print_error "Invalid choice" ;;
        esac
    done
}

# ============================================
# PERSONAL INFORMATION ATTACK MODE (FIXED)
# ============================================

setup_personal_info_attack() {
    clear_screen
    print_header "Personal Information Attack"
    
    # Check if collect_personal.sh exists
    if [[ ! -f "collect_personal.sh" ]]; then
        print_error "collect_personal.sh not found! Please place it in the same directory."
        echo ""
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read
        return 1
    fi
    
    # Run the collector using bash (no execute permission needed)
    bash collect_personal.sh
    
    # Check if personal_data.txt was created
    if [[ ! -f "personal_data.txt" ]]; then
        print_error "personal_data.txt not found! Data collection failed."
        return 1
    fi
    
    # Check for password generator
    if [[ ! -f "personal_generator.py" ]]; then
        print_error "personal_generator.py not found! Please place it in the same directory."
        return 1
    fi
    
    print_info "Generating password combinations from all mobile numbers..."
    python3 personal_generator.py 2>/dev/null
    
    if [[ -f "personal_passwords.txt" ]]; then
        DICT_FILE="personal_passwords.txt"
        ATTACK_MODE="dictionary"
        DICT_TYPE="personal"
        
        local line_count=$(wc -l < "personal_passwords.txt")
        print_success "Personal password list created: $line_count passwords"
        
        echo ""
        echo -e "${CYAN}Sample passwords (first 20):${NC}"
        head -20 "$DICT_FILE"
        
        rm -f personal_data.txt
    else
        print_error "Password generation failed"
        return 1
    fi
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
    return 0
}

# ============================================
# STEP 3B: DICTIONARY TYPE SELECTION
# ============================================

select_dictionary_type() {
    clear_screen
    print_header "Dictionary Type"
    
    echo -e "${WHITE}Choose dictionary type:${NC}"
    echo ""
    
    print_choice "1" "Default Common Passwords"
    print_choice "2" "RockYou Dictionary (Large)"
    print_choice "3" "Custom Wordlist"
    print_choice "4" "Generated Dictionary (Rules based)"
    print_choice "5" "Combined Attack (Multi-wordlist)"
    print_choice "6" "Downloaded Password Lists (from Option 5)"
    echo ""
    
    while true; do
        echo -e "${CYAN}Select option [1-6]:${NC}"
        read choice
        
        case $choice in
            1) DICT_TYPE="default"; break ;;
            2) DICT_TYPE="rockyou"; break ;;
            3) DICT_TYPE="custom"; break ;;
            4) DICT_TYPE="generated"; break ;;
            5) DICT_TYPE="combined"; break ;;
            6) DICT_TYPE="downloaded"; break ;;
            *) print_error "Invalid choice" ;;
        esac
    done
}

# ============================================
# DICTIONARY SETUP FUNCTIONS
# ============================================

setup_dictionary() {
    select_dictionary_type
    
    case $DICT_TYPE in
        "default")
            create_default_dictionary
            DICT_FILE="common_passwords.txt"
            print_success "Using default password list"
            ;;
        "rockyou")
            setup_rockyou_dictionary
            ;;
        "custom")
            setup_custom_dictionary
            ;;
        "generated")
            setup_generated_dictionary
            ;;
        "combined")
            setup_combined_dictionary
            ;;
        "downloaded")
            setup_downloaded_dictionary
            ;;
    esac
    
    if [[ -f "$DICT_FILE" ]]; then
        local line_count=$(wc -l < "$DICT_FILE" 2>/dev/null || echo "0")
        print_success "Dictionary loaded: $(basename "$DICT_FILE")"
        print_info "Passwords: $line_count"
    fi
    
    sleep 2
}

create_default_dictionary() {
    > common_passwords.txt
    print_info "Created empty common_passwords.txt file. Add passwords manually if needed."
}

setup_rockyou_dictionary() {
    clear_screen
    print_header "RockYou Dictionary"
    
    if [[ -f "rockyou.txt" ]]; then
        DICT_FILE="rockyou.txt"
        print_success "rockyou.txt already exists"
        return
    fi
    
    echo -e "${WHITE}RockYou is a large password dictionary (14M passwords)${NC}"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "1. Download from internet (≈134 MB compressed, ~139 MB uncompressed)"
    echo "2. Use smaller version (10K passwords)"
    echo "3. Use existing file"
    echo ""
    
    echo -e "${CYAN}Select option [1-3]:${NC}"
    read option
    
    case $option in
        1)
            print_info "Downloading rockyou.txt.gz from Kali Linux repository..."
            wget "https://gitlab.com/kalilinux/packages/wordlists/-/raw/kali/master/rockyou.txt.gz" -O rockyou.txt.gz
            if [[ $? -eq 0 && -f "rockyou.txt.gz" ]]; then
                print_info "Decompressing (this may take a moment)..."
                if command -v gunzip &> /dev/null; then
                    gunzip -f rockyou.txt.gz
                    if [[ -f "rockyou.txt" ]]; then
                        DICT_FILE="rockyou.txt"
                        print_success "Downloaded and extracted successfully"
                    else
                        print_error "Extraction failed"
                        create_default_dictionary
                        DICT_FILE="common_passwords.txt"
                    fi
                else
                    print_error "gunzip not found, cannot decompress"
                    create_default_dictionary
                    DICT_FILE="common_passwords.txt"
                fi
            else
                print_error "Download failed, using default dictionary"
                create_default_dictionary
                DICT_FILE="common_passwords.txt"
            fi
            ;;
        2)
            print_info "Creating smaller rockyou subset..."
            > rockyou_small.txt
            DICT_FILE="rockyou_small.txt"
            print_success "Created rockyou_small.txt (empty)"
            ;;
        3)
            echo -e "${CYAN}Enter path to rockyou.txt:${NC}"
            read -e dict_path
            dict_path="${dict_path//\'/}"
            dict_path="${dict_path//\"/}"
            dict_path="${dict_path/#\~/$HOME}"
            
            if [[ -f "$dict_path" ]]; then
                DICT_FILE="$dict_path"
                print_success "Using existing file"
            else
                print_error "File not found, using default"
                create_default_dictionary
                DICT_FILE="common_passwords.txt"
            fi
            ;;
        *)
            print_error "Invalid option, using default"
            create_default_dictionary
            DICT_FILE="common_passwords.txt"
            ;;
    esac
}

setup_custom_dictionary() {
    clear_screen
    print_header "Custom Dictionary"
    
    while true; do
        echo -e "${CYAN}Enter dictionary file path:${NC}"
        read -e dict_path
        
        dict_path="${dict_path//\'/}"
        dict_path="${dict_path//\"/}"
        dict_path="${dict_path/#\~/$HOME}"
        
        if [[ -z "$dict_path" ]]; then
            print_error "No file provided"
            continue
        fi
        
        if [[ ! -f "$dict_path" ]]; then
            print_error "File not found: $dict_path"
            continue
        else
            DICT_FILE="$dict_path"
            break
        fi
    done
}

setup_generated_dictionary() {
    clear_screen
    print_header "Generated Dictionary"
    
    echo -e "${WHITE}Create dictionary based on rules:${NC}"
    echo ""
    
    echo -e "${CYAN}Base words (comma separated):${NC}"
    read base_words
    
    echo -e "${CYAN}Add numbers at end? (y/n):${NC}"
    read add_numbers
    
    echo -e "${CYAN}Add common suffixes? (y/n):${NC}"
    read add_suffixes
    
    echo -e "${CYAN}Maximum variations per word:${NC}"
    read max_variations
    
    cat > generate_dict.py << 'EOF'
import sys
import itertools

def generate_dictionary(base_words, add_numbers, add_suffixes, max_vars):
    words = [w.strip() for w in base_words.split(',') if w.strip()]
    results = set(words)
    
    suffixes = ['123', '!', '@', '#', '1234', '2024', '2023', 'abc', 'xyz'] if add_suffixes else []
    numbers = ['', '1', '12', '123', '1234', '12345', '123456'] if add_numbers else ['']
    
    for word in words:
        count = 0
        
        for num in numbers:
            if count >= max_vars:
                break
            results.add(word + num)
            count += 1
        
        for suffix in suffixes:
            if count >= max_vars:
                break
            results.add(word + suffix)
            count += 1
        
        if count < max_vars:
            results.add(word.capitalize())
            count += 1
        
        if count < max_vars:
            results.add(word.upper())
            count += 1
    
    return sorted(results)

if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python3 generate_dict.py <base_words> <add_nums> <add_suffixes> <max_vars>")
        sys.exit(1)
    
    base_words = sys.argv[1]
    add_nums = sys.argv[2].lower() == 'y'
    add_suffixes = sys.argv[3].lower() == 'y'
    max_vars = int(sys.argv[4])
    
    passwords = generate_dictionary(base_words, add_nums, add_suffixes, max_vars)
    
    with open("generated_dict.txt", "w") as f:
        for pwd in passwords:
            f.write(pwd + "\n")
    
    print(f"Generated {len(passwords)} passwords")
EOF
    
    python3 generate_dict.py "$base_words" "$add_numbers" "$add_suffixes" "$max_variations" 2>/dev/null
    
    if [[ -f "generated_dict.txt" ]]; then
        DICT_FILE="generated_dict.txt"
        local line_count=$(wc -l < "generated_dict.txt")
        print_success "Generated dictionary with $line_count passwords"
    else
        print_error "Generation failed, using default"
        create_default_dictionary
        DICT_FILE="common_passwords.txt"
    fi
    
    rm -f generate_dict.py
}

setup_combined_dictionary() {
    clear_screen
    print_header "Combined Dictionary"
    
    print_info "Creating combined dictionary..."
    
    > combined_dict.txt
    
    if [[ -f "rockyou.txt" ]]; then
        cat rockyou.txt >> combined_dict.txt 2>/dev/null
    fi
    
    echo -e "${CYAN}Add more dictionary files? (y/n):${NC}"
    read add_more
    
    while [[ "$add_more" =~ ^[Yy]$ ]]; do
        echo -e "${CYAN}Enter file path:${NC}"
        read -e dict_path
        
        dict_path="${dict_path//\'/}"
        dict_path="${dict_path//\"/}"
        dict_path="${dict_path/#\~/$HOME}"
        
        if [[ -f "$dict_path" ]]; then
            cat "$dict_path" >> combined_dict.txt 2>/dev/null
            print_success "Added: $(basename "$dict_path")"
        else
            print_error "File not found"
        fi
        
        echo -e "${CYAN}Add another? (y/n):${NC}"
        read add_more
    done
    
    if [[ -f "combined_dict.txt" ]]; then
        sort -u combined_dict.txt -o combined_dict_unique.txt
        DICT_FILE="combined_dict_unique.txt"
        local line_count=$(wc -l < "$DICT_FILE")
        print_success "Combined dictionary created: $line_count unique passwords"
    else
        DICT_FILE="common_passwords.txt"
        print_info "Using default dictionary"
    fi
}

# ============================================
# DOWNLOAD PASSWORD LIST
# ============================================

download_password_list() {
    clear_screen
    print_header "Download Password List"
    
    declare -A lists=(
        ["Worst 500"]="500-worst-passwords.txt"
        ["Common 10K"]="10k-most-common.txt"
        ["NCSC 100K"]="100k-most-used-passwords-NCSC.txt"
        ["Decades 1900-2020"]="1900-2020.txt"
        ["2020 Top 200"]="2020-200_most_used_passwords.txt"
        ["2023 Top 200"]="2023-200_most_used_passwords.txt"
        ["2024 Top 197"]="2024-197_most_used_passwords.txt"
        ["2025 Top 199"]="2025-199_most_used_passwords.txt"
        ["PWDB 1K"]="Pwdb_top-1000.txt"
        ["PWDB 10K"]="Pwdb_top-10000.txt"
        ["PWDB 100K"]="Pwdb_top-100000.txt"
    )
    
    local sorted_names=()
    for name in "${!lists[@]}"; do
        sorted_names+=("$name")
    done
    IFS=$'\n' sorted_names=($(sort <<<"${sorted_names[*]}"))
    unset IFS
    
    local available=()
    local unavailable=()
    for name in "${sorted_names[@]}"; do
        filename="${lists[$name]}"
        if [[ -f "$filename" ]]; then
            available+=("$name")
        else
            unavailable+=("$name")
        fi
    done
    
    echo -e "${GREEN}┌───────────── Already Downloaded ─────────────┐${NC}"
    if [[ ${#available[@]} -eq 0 ]]; then
        echo -e "${WHITE}│${NC}              ${YELLOW}(none)${NC}                         ${WHITE}│${NC}"
    else
        for name in "${available[@]}"; do
            printf "${WHITE}│${NC}  ${GREEN}✓${NC}  %-40s ${WHITE}│${NC}\n" "$name"
        done
    fi
    echo -e "${GREEN}└──────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${CYAN}┌─────────── Available to Download ───────────┐${NC}"
    if [[ ${#unavailable[@]} -eq 0 ]]; then
        echo -e "${WHITE}│${NC}         ${GREEN}All lists already downloaded!${NC}         ${WHITE}│${NC}"
        echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
        echo ""
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read
        return
    fi
    
    local i=1
    declare -A option_map
    for name in "${unavailable[@]}"; do
        printf "${WHITE}│${NC}  ${CYAN}%2d${NC}.  %-40s ${WHITE}│${NC}\n" "$i" "$name"
        option_map[$i]="$name"
        ((i++))
    done
    echo -e "${CYAN}└──────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${YELLOW}╰─►${NC} ${WHITE}Select number to download [1-${#unavailable[@]}] or 0 to cancel:${NC}"
    read choice
    
    if [[ "$choice" -eq 0 ]] || [[ -z "$choice" ]]; then
        return
    fi
    
    local selected_name="${option_map[$choice]}"
    if [[ -z "$selected_name" ]]; then
        print_error "Invalid selection"
        sleep 1
        return
    fi
    
    local selected_file="${lists[$selected_name]}"
    
    if [[ -f "$selected_file" ]]; then
        print_warning "File already exists: $selected_file"
        sleep 1
        return
    fi
    
    print_info "Downloading: $selected_name"
    
    if ! command -v git &> /dev/null; then
        print_info "git not found. Installing git..."
        pkg install git -y
    fi
    
    local temp_dir="SecLists_temp_$$"
    print_info "Cloning repository (this may take a moment)..."
    
    git clone --depth 1 https://github.com/NRXQuantum/SecLists.git "$temp_dir" 2>/dev/null
    
    if [[ $? -ne 0 ]] || [[ ! -d "$temp_dir" ]]; then
        print_error "Failed to clone repository"
        rm -rf "$temp_dir" 2>/dev/null
        sleep 2
        return
    fi
    
    print_info "Searching for $selected_file..."
    local found_file=$(find "$temp_dir" -type f -name "$selected_file" | head -n1)
    
    if [[ -z "$found_file" ]]; then
        print_error "File not found in repository: $selected_file"
        rm -rf "$temp_dir"
        sleep 2
        return
    fi
    
    cp "$found_file" "./$selected_file"
    
    if [[ -f "./$selected_file" ]]; then
        print_success "Downloaded: $selected_name"
        local line_count=$(wc -l < "./$selected_file")
        print_info "Total passwords: $line_count"
    else
        print_error "Copy failed"
    fi
    
    rm -rf "$temp_dir"
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

setup_downloaded_dictionary() {
    clear_screen
    print_header "Select Downloaded Password List"
    
    declare -A lists=(
        ["Worst 500"]="500-worst-passwords.txt"
        ["Common 10K"]="10k-most-common.txt"
        ["NCSC 100K"]="100k-most-used-passwords-NCSC.txt"
        ["Decades 1900-2020"]="1900-2020.txt"
        ["2020 Top 200"]="2020-200_most_used_passwords.txt"
        ["2023 Top 200"]="2023-200_most_used_passwords.txt"
        ["2024 Top 197"]="2024-197_most_used_passwords.txt"
        ["2025 Top 199"]="2025-199_most_used_passwords.txt"
        ["PWDB 1K"]="Pwdb_top-1000.txt"
        ["PWDB 10K"]="Pwdb_top-10000.txt"
        ["PWDB 100K"]="Pwdb_top-100000.txt"
    )
    
    local sorted_names=()
    for name in "${!lists[@]}"; do
        sorted_names+=("$name")
    done
    IFS=$'\n' sorted_names=($(sort <<<"${sorted_names[*]}"))
    unset IFS
    
    local available_names=()
    local available_files=()
    for name in "${sorted_names[@]}"; do
        filename="${lists[$name]}"
        if [[ -f "$filename" ]]; then
            available_names+=("$name")
            available_files+=("$filename")
        fi
    done
    
    if [[ ${#available_names[@]} -eq 0 ]]; then
        print_error "No downloaded password lists found!"
        print_info "Please use option 5 from main menu to download first."
        echo ""
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read
        DICT_FILE=""
        return 1
    fi
    
    echo -e "${GREEN}┌─────────── Downloaded Lists ───────────┐${NC}"
    for i in "${!available_names[@]}"; do
        printf "${WHITE}│${NC}  ${CYAN}%2d${NC}.  %-40s ${WHITE}│${NC}\n" "$((i+1))" "${available_names[$i]}"
    done
    echo -e "${GREEN}└──────────────────────────────────────────────┘${NC}"
    echo ""
    
    echo -e "${CYAN}Select number (0 to cancel):${NC}"
    read selection
    
    if [[ "$selection" -eq 0 ]] || [[ -z "$selection" ]]; then
        return 1
    fi
    
    local idx=$((selection-1))
    if [[ $idx -lt 0 ]] || [[ $idx -ge ${#available_names[@]} ]]; then
        print_error "Invalid selection"
        sleep 1
        return 1
    fi
    
    DICT_FILE="${available_files[$idx]}"
    print_success "Selected: ${available_names[$idx]}"
    
    local line_count=$(wc -l < "$DICT_FILE" 2>/dev/null || echo "0")
    print_info "Passwords: $line_count"
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
    return 0
}

# ============================================
# STEP 3A: BRUTE FORCE SETUP
# ============================================

setup_brute_force() {
    clear_screen
    print_header "Character Set Selection"
    
    echo -e "${WHITE}Choose character set:${NC}"
    echo ""
    
    print_choice "1" "Lowercase letters (abc...)"
    print_choice "2" "Uppercase letters (ABC...)"
    print_choice "3" "Digits only (012...)"
    print_choice "4" "Lowercase + Digits (abc123)"
    print_choice "5" "Uppercase + Digits (ABC123)"
    print_choice "6" "All letters (abcABC)"
    print_choice "7" "All letters + Digits (abcABC123)"
    print_choice "8" "All characters (with symbols)"
    print_choice "9" "Custom character set"
    print_choice "10" "Advance - Complete Combos"
    echo ""
    
    while true; do
        echo -e "${CYAN}Select option [1-10]:${NC}"
        read choice
        
        case $choice in
            1) CHARSET="abcdefghijklmnopqrstuvwxyz"; break ;;
            2) CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZ"; break ;;
            3) CHARSET="0123456789"; break ;;
            4) CHARSET="abcdefghijklmnopqrstuvwxyz0123456789"; break ;;
            5) CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"; break ;;
            6) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; break ;;
            7) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"; break ;;
            8) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?/~"; break ;;
            9) 
                echo ""
                echo -e "${CYAN}Enter custom characters:${NC}"
                read custom_chars
                if [[ -n "$custom_chars" ]]; then
                    CHARSET="$custom_chars"
                    break
                else
                    print_error "Charset cannot be empty"
                fi 
                ;;
            10)
                clear_screen
                print_header "Advance - Character Combinations"
                
                echo -e "${WHITE}Choose advance combination:${NC}"
                echo ""
                print_choice "1" "Lowercase + Uppercase (aA bB)"
                print_choice "2" "Lowercase + Symbols (a! b@)"
                print_choice "3" "Uppercase + Symbols (A! B@)"
                print_choice "4" "Lowercase + Uppercase + Symbols (aA! bB@)"
                print_choice "5" "Everything Complete (All types)"
                echo ""
                
                while true; do
                    echo -e "${CYAN}Select advance option [1-5]:${NC}"
                    read advance_choice
                    
                    case $advance_choice in
                        1) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"; break ;;
                        2) CHARSET="abcdefghijklmnopqrstuvwxyz!@#$%^&*()_+-=[]{}|;:,.<>?/~"; break ;;
                        3) CHARSET="ABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+-=[]{}|;:,.<>?/~"; break ;;
                        4) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!@#$%^&*()_+-=[]{}|;:,.<>?/~"; break ;;
                        5) CHARSET="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?/~$€£¥₹±×÷=≠≈αβγΔπΣ"; break ;;
                        *) print_error "Invalid advance choice" ;;
                    esac
                done
                break
                ;;
            *) print_error "Invalid choice" ;;
        esac
    done
    
    echo ""
    print_header "Password Length"
    print_prompt "How many characters in password?"
    
    while true; do
        echo -e "${CYAN}Enter length (1-8 recommended, max 12):${NC}"
        read length
        
        if [[ "$length" =~ ^[0-9]+$ ]]; then
            if [[ $length -lt 1 ]]; then
                print_error "Length must be at least 1"
            elif [[ $length -gt 16 ]]; then
                print_warning "Length $length may take VERY LONG!"
                echo -e "${CYAN}Continue anyway? (y/n):${NC}"
                read confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    PASSWORD_LENGTH=$length
                    break
                fi
            elif [[ $length -gt 12 ]]; then
                print_warning "Length $length may take long time"
                echo -e "${CYAN}Continue anyway? (y/n):${NC}"
                read confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    PASSWORD_LENGTH=$length
                    break
                fi
            else
                PASSWORD_LENGTH=$length
                break
            fi
        else
            print_error "Please enter a valid number"
        fi
    done
    
    echo ""
    print_header "Known Characters"
    echo -e "${CYAN}Do you know any characters? (y/n):${NC}"
    read know_chars
    
    if [[ "$know_chars" =~ ^[Yy]$ ]]; then
        local pattern_array=()
        for ((i=0; i<PASSWORD_LENGTH; i++)); do
            pattern_array[i]="?"
        done
        
        local position=0
        
        while true; do
            clear_screen
            print_header "Pattern Builder"
            
            echo -e "${CYAN}Length:${NC} ${WHITE}$PASSWORD_LENGTH${NC}"
            echo -e "${CYAN}Position:${NC} ${WHITE}$((position+1))${NC}"
            echo ""
            
            echo -ne "${WHITE}Pattern:${NC}"
            echo -ne "    "
            for ((i=0; i<PASSWORD_LENGTH; i++)); do
                if [[ $i -eq $position ]]; then
                    echo -ne "${GREEN}[${pattern_array[$i]}]${NC} "
                else
                    echo -ne "${BLUE}[${pattern_array[$i]}]${NC} "
                fi
            done
            echo ""
            echo ""
            
            echo -e "${YELLOW}Controls:${NC}"
            echo -e "${WHITE}• Enter character to set${NC}"
            echo -e "${WHITE}• Space to clear${NC}"
            echo -e "${WHITE}• Enter to finish${NC}"
            echo -e "${WHITE}• n = next, p = previous${NC}"
            echo ""
            
            echo -e "${CYAN}Enter character for position $((position+1)):${NC}"
            read -n1 char
            echo ""
            
            case "$char" in
                "") 
                    echo -e "${CYAN}Finish pattern building? (y/n):${NC}"
                    read finish
                    if [[ "$finish" =~ ^[Yy]$ ]]; then
                        break
                    fi
                    ;;
                " ") pattern_array[$position]="?" ;;
                "n"|"N") 
                    ((position++))
                    if [[ $position -ge $PASSWORD_LENGTH ]]; then
                        position=0
                    fi
                    ;;
                "p"|"P") 
                    ((position--))
                    if [[ $position -lt 0 ]]; then
                        position=$((PASSWORD_LENGTH-1))
                    fi
                    ;;
                *) pattern_array[$position]="$char" ;;
            esac
        done
        
        PATTERN=""
        for ((i=0; i<PASSWORD_LENGTH; i++)); do
            PATTERN+="${pattern_array[$i]}"
        done
    else
        PATTERN=$(printf "%0.s?" $(seq 1 $PASSWORD_LENGTH))
    fi
    
    print_success "Brute force configured"
    print_info "Pattern: $PATTERN"
    print_info "Charset: ${#CHARSET} characters"
    
    local total=1
    local unknown_count=0
    for ((i=0; i<${#PATTERN}; i++)); do
        char="${PATTERN:$i:1}"
        if [[ "$char" == "?" ]]; then
            total=$((total * ${#CHARSET}))
            unknown_count=$((unknown_count + 1))
        fi
    done
    
    print_info "Unknown positions: $unknown_count"
    print_info "Total combinations: $(printf "%'d" $total)"
    
    if [[ $total -gt 10000000 ]]; then
        print_warning "WARNING: This may take VERY LONG time!"
        echo -e "${CYAN}Continue anyway? (y/n):${NC}"
        read confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    sleep 2
}

# ============================================
# STEP 3C: SINGLE PASSWORD TEST
# ============================================

setup_single_test() {
    clear_screen
    print_header "Single Password Test"
    
    echo -e "${CYAN}Enter password to test:${NC}"
    read -s password
    echo ""
    
    cat > single_test.py << 'EOF'
import sys
import pyzipper
import zipfile
import os

try:
    import PyPDF2
    HAS_PDF = True
except ImportError:
    HAS_PDF = False

try:
    import openpyxl
    HAS_EXCEL = True
except ImportError:
    try:
        import xlrd
        HAS_EXCEL = True
    except ImportError:
        HAS_EXCEL = False

def test_password_pdf(pdf_path, password):
    if not HAS_PDF:
        return False
    try:
        with open(pdf_path, 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            if reader.is_encrypted:
                result = reader.decrypt(password)
                return result == 1 or result == 2
    except:
        pass
    return False

def test_password_excel(excel_path, password):
    if not HAS_EXCEL:
        return False
    try:
        if excel_path.lower().endswith('.xlsx'):
            workbook = openpyxl.load_workbook(excel_path, read_only=True, data_only=True)
            return True
        elif excel_path.lower().endswith('.xls'):
            import xlrd
            workbook = xlrd.open_workbook(excel_path, password=password)
            return True
    except:
        pass
    return False

def test_password_powerpoint(ppt_path, password):
    try:
        cmd = f'7z t -p"{password}" "{ppt_path}" -y'
        result = os.system(cmd + " > /dev/null 2>&1")
        return result == 0
    except:
        return False

def test_password_word(doc_path, password):
    try:
        cmd = f'7z t -p"{password}" "{doc_path}" -y'
        result = os.system(cmd + " > /dev/null 2>&1")
        return result == 0
    except:
        return False

def test_password_zip(zip_path, password):
    try:
        pwd_bytes = password.encode('utf-8')
        try:
            with pyzipper.AESZipFile(zip_path, 'r') as zf:
                for info in zf.infolist():
                    if not info.filename.endswith('/'):
                        try:
                            zf.read(info.filename, pwd=pwd_bytes)
                            return True, "ZIP (AES)"
                        except:
                            return False, "Wrong password"
        except:
            pass
        try:
            with zipfile.ZipFile(zip_path, 'r') as zf:
                for info in zf.infolist():
                    if not info.filename.endswith('/'):
                        try:
                            zf.read(info.filename, pwd=pwd_bytes)
                            return True, "Standard ZIP"
                        except:
                            return False, "Wrong password"
        except Exception as e:
            return False, f"ZIP error: {str(e)}"
    except Exception as e:
        return False, f"Error: {str(e)}"
    return False, "Not a ZIP file"

def test_password_7z(archive_path, password):
    try:
        cmd = f'7z t -p"{password}" "{archive_path}" -y'
        result = os.system(cmd + " > /dev/null 2>&1")
        if result == 0:
            return True, "7Z Archive"
        else:
            return False, "Wrong password"
    except:
        return False, "7Z test failed"

def test_password_rar(archive_path, password):
    try:
        cmd = f'unrar t -p"{password}" "{archive_path}"'
        result = os.system(cmd + " > /dev/null 2>&1")
        if result == 0:
            return True, "RAR Archive"
        else:
            return False, "Wrong password"
    except:
        return False, "RAR test failed"

def test_single_password(archive_path, password, archive_type="auto"):
    if archive_type == "pdf":
        if test_password_pdf(archive_path, password):
            return True, "PDF Document"
    
    if archive_type == "excel":
        if test_password_excel(archive_path, password):
            return True, "Excel File"
    
    if archive_type == "powerpoint":
        if test_password_powerpoint(archive_path, password):
            return True, "PowerPoint File"
    
    if archive_type == "word":
        if test_password_word(archive_path, password):
            return True, "Word Document"
    
    if archive_type in ["zip", "aes", "standard"]:
        success, msg = test_password_zip(archive_path, password)
        if success:
            return True, msg
    
    if archive_type == "7z":
        success, msg = test_password_7z(archive_path, password)
        if success:
            return True, msg
    
    if archive_type == "rar":
        success, msg = test_password_rar(archive_path, password)
        if success:
            return True, msg
    
    if archive_type == "auto":
        if test_password_pdf(archive_path, password):
            return True, "PDF Document"
        if test_password_excel(archive_path, password):
            return True, "Excel File"
        if test_password_powerpoint(archive_path, password):
            return True, "PowerPoint File"
        if test_password_word(archive_path, password):
            return True, "Word Document"
        success, msg = test_password_zip(archive_path, password)
        if success:
            return True, msg
        success, msg = test_password_7z(archive_path, password)
        if success:
            return True, msg
        success, msg = test_password_rar(archive_path, password)
        if success:
            return True, msg
    
    return False, "Password incorrect"

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 single_test.py <archive> <password> [type]")
        sys.exit(1)
    
    archive = sys.argv[1]
    password = sys.argv[2]
    archive_type = sys.argv[3] if len(sys.argv) > 3 else "auto"
    
    if not os.path.exists(archive):
        print("Error: File not found!")
        sys.exit(1)
    
    success, message = test_single_password(archive, password, archive_type)
    
    if success:
        print("SUCCESS:1")
        print(f"Password: {password}")
        print(f"Archive Type: {message}")
    else:
        print("SUCCESS:0")
        print(f"Message: {message}")
EOF
    
    echo -e "${BLUE}[*]${NC} Testing password: ${YELLOW}$password${NC}"
    result=$(python3 single_test.py "$CURRENT_FILE" "$password" "$ZIP_TYPE" 2>/dev/null)
    
    if echo "$result" | grep -q "SUCCESS:1"; then
        echo ""
        print_success "PASSWORD IS CORRECT!"
        echo -e "${GREEN}✓ Password:${NC} ${WHITE}$password${NC}"
        archive_type_msg=$(echo "$result" | grep "Archive Type" | cut -d: -f2-)
        echo -e "${GREEN}✓ Archive Type:${NC} ${WHITE}$archive_type_msg${NC}"
        
        echo ""
        echo -e "${CYAN}Extract files? (y/n):${NC}"
        read extract
        
        if [[ "$extract" =~ ^[Yy]$ ]]; then
            extract_files "$password"
        fi
    else
        echo ""
        print_error "PASSWORD IS WRONG!"
        echo -e "${RED}✗ Password:${NC} ${WHITE}$password${NC}"
        error_msg=$(echo "$result" | grep "Message" | cut -d: -f2-)
        echo -e "${RED}✗ Reason:${NC} ${WHITE}$error_msg${NC}"
    fi
    
    rm -f single_test.py
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
    return 1
}

# ============================================
# EXTRACTION FUNCTION
# ============================================

extract_files() {
    local password="$1"
    
    cat > extract_files.py << 'EOF'
import sys
import pyzipper
import zipfile
import os
import shutil

def extract_pdf(pdf_path, password, output_dir):
    try:
        import PyPDF2
        with open(pdf_path, 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            if reader.is_encrypted:
                reader.decrypt(password)
            
            writer = PyPDF2.PdfWriter()
            for page_num in range(len(reader.pages)):
                writer.add_page(reader.pages[page_num])
            
            output_file = os.path.join(output_dir, os.path.basename(pdf_path))
            with open(output_file, 'wb') as out_file:
                writer.write(out_file)
            print(f"Extracted PDF file")
            return True
    except:
        return False

def extract_excel(excel_path, password, output_dir):
    try:
        if excel_path.lower().endswith('.xlsx'):
            import openpyxl
            workbook = openpyxl.load_workbook(excel_path, data_only=True)
            output_file = os.path.join(output_dir, os.path.basename(excel_path))
            workbook.save(output_file)
            print(f"Extracted Excel file")
            return True
        elif excel_path.lower().endswith('.xls'):
            shutil.copy2(excel_path, output_dir)
            print(f"Copied Excel file")
            return True
    except:
        return False

def extract_powerpoint(ppt_path, password, output_dir):
    try:
        cmd = f'7z x -p"{password}" -o"{output_dir}" "{ppt_path}" -y'
        result = os.system(cmd + " > /dev/null 2>&1")
        if result == 0:
            print(f"Extracted PowerPoint file")
            return True
    except:
        return False

def extract_word(doc_path, password, output_dir):
    try:
        cmd = f'7z x -p"{password}" -o"{output_dir}" "{doc_path}" -y'
        result = os.system(cmd + " > /dev/null 2>&1")
        if result == 0:
            print(f"Extracted Word document")
            return True
    except:
        return False

def extract_zip(archive_path, password, output_dir):
    try:
        with pyzipper.AESZipFile(archive_path, 'r') as zf:
            zf.extractall(path=output_dir, pwd=password.encode())
            print(f"Extracted files (AES ZIP)")
            return True
    except:
        try:
            with zipfile.ZipFile(archive_path, 'r') as zf:
                zf.extractall(path=output_dir, pwd=password.encode())
                print(f"Extracted files (Standard ZIP)")
                return True
        except:
            return False

def extract_7z(archive_path, password, output_dir):
    try:
        if os.path.exists(output_dir):
            shutil.rmtree(output_dir)
        os.makedirs(output_dir, exist_ok=True)
        cmd = f'7z x -p"{password}" -o"{output_dir}" "{archive_path}" -y'
        result = os.system(cmd + " > /dev/null 2>&1")
        if result == 0:
            print(f"Extracted files (7Z)")
            return True
        else:
            return False
    except:
        return False

def extract_rar(archive_path, password, output_dir):
    try:
        if os.path.exists(output_dir):
            shutil.rmtree(output_dir)
        os.makedirs(output_dir, exist_ok=True)
        cmd = f'unrar x -p"{password}" "{archive_path}" "{output_dir}/" -y'
        result = os.system(cmd + " > /dev/null 2>&1")
        if result == 0:
            print(f"Extracted files (RAR)")
            return True
        else:
            return False
    except:
        return False

def extract_archive(archive_path, password, output_dir, archive_type="auto"):
    if archive_type == "pdf":
        return extract_pdf(archive_path, password, output_dir)
    elif archive_type == "excel":
        return extract_excel(archive_path, password, output_dir)
    elif archive_type == "powerpoint":
        return extract_powerpoint(archive_path, password, output_dir)
    elif archive_type == "word":
        return extract_word(archive_path, password, output_dir)
    elif archive_type == "zip" or archive_type == "aes" or archive_type == "standard":
        return extract_zip(archive_path, password, output_dir)
    elif archive_type == "7z":
        return extract_7z(archive_path, password, output_dir)
    elif archive_type == "rar":
        return extract_rar(archive_path, password, output_dir)
    elif archive_type == "auto":
        if extract_pdf(archive_path, password, output_dir):
            return True
        if extract_excel(archive_path, password, output_dir):
            return True
        if extract_powerpoint(archive_path, password, output_dir):
            return True
        if extract_word(archive_path, password, output_dir):
            return True
        if extract_zip(archive_path, password, output_dir):
            return True
        if extract_7z(archive_path, password, output_dir):
            return True
        if extract_rar(archive_path, password, output_dir):
            return True
    return False

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python3 extract_files.py <archive> <password> <output_dir> [type]")
        sys.exit(1)
    
    archive = sys.argv[1]
    password = sys.argv[2]
    output_dir = sys.argv[3]
    archive_type = sys.argv[4] if len(sys.argv) > 4 else "auto"
    
    success = extract_archive(archive, password, output_dir, archive_type)
    sys.exit(0 if success else 1)
EOF
    
    echo -e "${BLUE}[*]${NC} Extracting files..."
    
    if python3 extract_files.py "$CURRENT_FILE" "$password" "$OUTPUT_DIR" "$ZIP_TYPE" 2>/dev/null; then
        print_success "Files extracted to: $OUTPUT_DIR"
        echo -e "${CYAN}Extracted files:${NC}"
        ls -la "$OUTPUT_DIR" 2>/dev/null | head -10
    else
        print_error "Extraction failed"
    fi
    
    rm -f extract_files.py
}

# ============================================
# SMART DICTIONARY ATTACK SETUP
# ============================================

setup_smart_dictionary() {
    clear_screen
    print_header "Smart Dictionary Attack"
    
    echo -e "${WHITE}Smart attack uses rules and mutations:${NC}"
    echo ""
    
    echo -e "${CYAN}Base dictionary file:${NC}"
    read -e base_dict
    
    base_dict="${base_dict//\'/}"
    base_dict="${base_dict//\"/}"
    base_dict="${base_dict/#\~/$HOME}"
    
    if [[ ! -f "$base_dict" ]]; then
        print_error "Base dictionary not found, using default"
        create_default_dictionary
        base_dict="common_passwords.txt"
    fi
    
    echo -e "${CYAN}Apply mutation rules? (y/n):${NC}"
    read apply_rules
    
    if [[ "$apply_rules" =~ ^[Yy]$ ]]; then
        print_info "Creating smart dictionary with mutations..."
        
        cat > smart_dict.py << 'EOF'
import sys

def mutate_password(password):
    mutations = set([password])
    
    mutations.add(password.lower())
    mutations.add(password.upper())
    mutations.add(password.capitalize())
    
    for num in ['', '1', '123', '1234', '123456', '2024', '2023', '2025', '!', '@', '#', '!@#']:
        mutations.add(password + num)
        mutations.add(password.lower() + num)
    
    leet = str.maketrans('aeiost', '431057')
    leet_version = password.translate(leet)
    mutations.add(leet_version)
    mutations.add(leet_version.lower())
    
    if len(password) <= 8:
        mutations.add(password[::-1])
    
    mutations.add(password + password)
    mutations.add(password + password.lower())
    
    return mutations

def create_smart_dictionary(input_file, output_file):
    all_passwords = set()
    
    with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
        passwords = [line.strip() for line in f if line.strip()]
    
    print(f"[*] Base passwords: {len(passwords)}")
    
    for i, pwd in enumerate(passwords):
        if i % 100 == 0:
            print(f"[*] Processing: {i}/{len(passwords)}", end='\r')
        
        mutations = mutate_password(pwd)
        all_passwords.update(mutations)
    
    print(f"\n[*] Total mutations: {len(all_passwords)}")
    
    with open(output_file, 'w') as f:
        for pwd in sorted(all_passwords, key=len):
            f.write(pwd + '\n')
    
    return len(all_passwords)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 smart_dict.py <input_dict> <output_dict>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    count = create_smart_dictionary(input_file, output_file)
    print(f"[+] Created smart dictionary: {output_file} ({count} passwords)")
EOF
        
        python3 smart_dict.py "$base_dict" "smart_dict.txt" 2>/dev/null
        
        if [[ -f "smart_dict.txt" ]]; then
            DICT_FILE="smart_dict.txt"
            DICT_TYPE="smart"
            local line_count=$(wc -l < "smart_dict.txt")
            print_success "Smart dictionary created: $line_count passwords"
        else
            DICT_FILE="$base_dict"
            print_info "Using base dictionary (mutation failed)"
        fi
        
        rm -f smart_dict.py
    else
        DICT_FILE="$base_dict"
        print_info "Using base dictionary without mutations"
    fi
    
    sleep 2
}

# ============================================
# STEP 4: ATTACK SUMMARY
# ============================================

show_attack_summary() {
    clear_screen
    print_header "Attack Summary"
    
    echo -e "${CYAN}Archive:${NC} ${WHITE}$(basename "$CURRENT_FILE")${NC}"
    echo -e "${CYAN}Type:${NC} ${WHITE}$ZIP_TYPE${NC}"
    
    case $ATTACK_MODE in
        "bruteforce")
            local total=1
            local unknown_count=0
            for ((i=0; i<${#PATTERN}; i++)); do
                char="${PATTERN:$i:1}"
                if [[ "$char" == "?" ]]; then
                    total=$((total * ${#CHARSET}))
                    unknown_count=$((unknown_count + 1))
                fi
            done
            
            echo -e "${CYAN}Mode:${NC} ${WHITE}Brute Force${NC}"
            echo -e "${CYAN}Pattern:${NC} ${WHITE}$PATTERN${NC}"
            echo -e "${CYAN}Length:${NC} ${WHITE}$PASSWORD_LENGTH${NC}"
            echo -e "${CYAN}Charset:${NC} ${WHITE}${#CHARSET} chars${NC}"
            echo -e "${CYAN}Unknown positions:${NC} ${WHITE}$unknown_count${NC}"
            echo -e "${CYAN}Combinations:${NC} ${WHITE}$(printf "%'d" $total)${NC}"
            
            local speed=1000
            local seconds=$((total / speed))
            ;;
        
        "dictionary"|"smartdict"|"personal")
            if [[ -f "$DICT_FILE" ]]; then
                local line_count=$(wc -l < "$DICT_FILE" 2>/dev/null || echo "0")
                echo -e "${CYAN}Mode:${NC} ${WHITE}Dictionary Attack${NC}"
                echo -e "${CYAN}Dictionary:${NC} ${WHITE}$(basename "$DICT_FILE")${NC}"
                echo -e "${CYAN}Dictionary Type:${NC} ${WHITE}$DICT_TYPE${NC}"
                echo -e "${CYAN}Passwords:${NC} ${WHITE}$(printf "%'d" $line_count)${NC}"
                
                local speed=5000
                local seconds=$((line_count / speed))
            fi
            ;;
    esac
    
    if [[ -n "$seconds" ]]; then
        echo ""
        echo -e "${YELLOW}ESTIMATION:${NC}"
        if [[ $seconds -gt 86400 ]]; then
            local days=$((seconds / 86400))
            local hours=$(((seconds % 86400) / 3600))
            echo -e "${CYAN}Estimated time:${NC} ${RED}$days days, $hours hours${NC}"
            print_warning "This may take VERY LONG!"
        elif [[ $seconds -gt 3600 ]]; then
            local hours=$((seconds / 3600))
            local minutes=$(((seconds % 3600) / 60))
            echo -e "${CYAN}Estimated time:${NC} ${YELLOW}$hours hours, $minutes minutes${NC}"
            print_warning "This may take some time"
        elif [[ $seconds -gt 60 ]]; then
            local minutes=$((seconds / 60))
            echo -e "${CYAN}Estimated time:${NC} ${GREEN}$minutes minutes${NC}"
        else
            echo -e "${CYAN}Estimated time:${NC} ${GREEN}$seconds seconds${NC}"
        fi
        echo -e "${CYAN}Estimated speed:${NC} ${WHITE}$speed passwords/second${NC}"
        
        if [[ "$ATTACK_MODE" == "bruteforce" ]] && [[ $total -gt 10000000 ]]; then
            echo ""
            print_warning "WARNING: Very large search space!"
            echo -e "${WHITE}Consider using dictionary attack instead.${NC}"
        fi
    fi
    
    echo ""
    print_line
    
    echo ""
    echo -e "${CYAN}Start attack? (y/n):${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================
# STEP 5: EXECUTE ATTACK
# ============================================

execute_attack() {
    clear_screen
    print_header "Starting Attack"
    
    if [[ ! -f "$PYTHON_CRACKER" ]]; then
        print_error "Required file '$PYTHON_CRACKER' not found!"
        print_error "Please ensure 'advanced+cracker.py' is present in the current directory."
        echo ""
        echo -e "${CYAN}Press Enter to continue...${NC}"
        read
        return 1
    fi
    
    case $ATTACK_MODE in
        "bruteforce")
            echo -e "${BLUE}[*]${NC} Starting brute force attack..."
            echo -e "${CYAN}File Type:${NC} $ZIP_TYPE"
            echo -e "${CYAN}Pattern:${NC} $PATTERN"
            echo -e "${CYAN}Charset:${NC} ${#CHARSET} characters"
            echo ""
            
            python3 "$PYTHON_CRACKER" "brute" "$CURRENT_FILE" "$ZIP_TYPE" "$CHARSET" "$PATTERN"
            ;;
        
        "dictionary"|"smartdict"|"personal")
            echo -e "${BLUE}[*]${NC} Starting dictionary attack..."
            echo -e "${CYAN}File Type:${NC} $ZIP_TYPE"
            echo -e "${CYAN}Dictionary:${NC} $(basename "$DICT_FILE")"
            echo -e "${CYAN}Dictionary Type:${NC} $DICT_TYPE"
            echo ""
            
            python3 "$PYTHON_CRACKER" "dict" "$CURRENT_FILE" "$ZIP_TYPE" "$DICT_FILE"
            ;;
    esac
    
    if [[ $? -eq 0 ]] && [[ -f "crack_result.txt" ]]; then
        echo ""
        print_success "Attack completed successfully!"
        echo ""
        echo -e "${CYAN}Result:${NC}"
        cat "crack_result.txt"
        
        if [[ -d "$OUTPUT_DIR" ]]; then
            echo ""
            echo -e "${CYAN}Extracted files in:${NC} $OUTPUT_DIR"
            ls -la "$OUTPUT_DIR" 2>/dev/null | head -20
        fi
    else
        echo ""
        print_error "Attack failed or password not found"
    fi
    
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

# ============================================
# HELP SCREEN
# ============================================

show_help() {
    clear_screen
    print_header "Help & Instructions"
    
    echo -e "${WHITE}This tool can crack encrypted archives using:${NC}"
    echo ""
    echo -e "${GREEN}1. Brute Force Attack${NC}"
    echo "   - Specify character set"
    echo "   - Set password length"
    echo "   - Build pattern with known characters"
    echo "   - ✓ Fixed: Correct generation order (a-z, A-Z, 0-9, symbols)"
    echo ""
    echo -e "${GREEN}2. Dictionary Attack${NC}"
    echo "   - Use password list file"
    echo "   - Multiple dictionary types"
    echo "   - ✓ Fixed: 100% complete হলে automatic break"
    echo ""
    echo -e "${GREEN}3. Personal Information Attack${NC}"
    echo "   - Generate passwords from personal info"
    echo "   - Multiple mobile numbers support"
    echo "   - Name + Year (Minhaz2008)"
    echo "   - Name + Mobile (Sajim01852288884)"
    echo "   - Name + Girlfriend (MinhazPriya)"
    echo "   - 100+ advanced password patterns"
    echo "   - Smart mutations & variations"
    echo ""
    echo -e "${GREEN}4. Supported File Formats:${NC}"
    echo "   • Standard ZIP (zipcrypt)"
    echo "   • AES Encrypted ZIP (WinZip, 7-Zip AES)"
    echo "   • 7Z Archive (7-Zip format)"
    echo "   • RAR Archive (WinRAR)"
    echo "   • PDF Document (Adobe PDF) ✓ FIXED"
    echo "   • Excel File (XLS/XLSX) ✓ FIXED"
    echo "   • PowerPoint File (PPT/PPTX) ✓ FIXED (7z fallback)"
    echo "   • Word Document (DOC/DOCX) ✓ FIXED (7z fallback)"
    echo ""
    echo -e "${GREEN}5. Download Password Lists${NC}"
    echo "   - Download specific password lists from GitHub"
    echo "   - Lists are categorized by size and usage"
    echo "   - Already downloaded lists are shown as installed"
    echo ""
    echo -e "${YELLOW}Requirements:${NC}"
    echo "• Python3"
    echo "• pyzipper (for AES encryption)"
    echo "• unrar (for RAR support)"
    echo "• p7zip (for 7Z support)"
    echo "• PyPDF2 (for PDF support)"
    echo "• openpyxl (for Excel XLSX support)"
    echo "• xlrd (for Excel XLS support)"
    echo "• python-pptx (optional, for PowerPoint support - 7z fallback available)"
    echo "• python-docx (optional, for Word support - 7z fallback available)"
    echo ""
    echo -e "${CYAN}Press Enter to continue...${NC}"
    read
}

# ============================================
# CLEANUP
# ============================================

cleanup() {
    rm -f generate_dict.py smart_dict.py single_test.py extract_files.py 2>/dev/null
    rm -f personal_data.txt 2>/dev/null
    print_info "Cleanup completed"
}

# ============================================
# MAIN FLOW FUNCTION
# ============================================

main_flow() {
    if ! select_file; then
        print_error "File selection cancelled"
        sleep 2
        return 1
    fi
    
    select_file_type
    
    select_attack_mode
    
    case $ATTACK_MODE in
        "bruteforce")
            if ! setup_brute_force; then
                print_error "Brute force setup cancelled"
                sleep 2
                return 1
            fi
            ;;
        "dictionary")
            setup_dictionary
            ;;
        "smartdict")
            setup_smart_dictionary
            ;;
        "personal")
            if ! setup_personal_info_attack; then
                print_error "Personal information setup failed"
                sleep 2
                return 1
            fi
            ;;
        "single")
            setup_single_test
            return 0
            ;;
    esac
    
    if show_attack_summary; then
        execute_attack
    else
        print_info "Attack cancelled"
        sleep 1
    fi
    
    return 0
}

# ============================================
# MAIN PROGRAM
# ============================================

main() {
    trap cleanup EXIT
    
    check_requirements
    
    while true; do
        clear_screen
        
        echo -e "${PURPLE}"
        echo "╠══════════════════════════════════════════════╣"
        echo "║                                              ║"
        echo "║   1. Start Password Cracker                 ║"
        echo "║   2. Test Single Password                   ║"
        echo "║   3. Check Requirements                     ║"
        echo "║   4. View Help                              ║"
        echo "║   5. Download Password List                 ║"
        echo "║   6. Exit                                   ║"
        echo "║                                              ║"
        echo "╚══════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""
        
        echo -e "${CYAN}Select option [1-6]:${NC}"
        read choice
        
        case $choice in
            1)
                main_flow
                ;;
            2)
                clear_screen
                print_header "Single Password Test"
                
                if select_file; then
                    select_file_type
                    ATTACK_MODE="single"
                    setup_single_test
                fi
                ;;
            3)
                check_requirements
                echo ""
                echo -e "${CYAN}Press Enter to continue...${NC}"
                read
                ;;
            4)
                show_help
                ;;
            5)
                download_password_list
                ;;
            6)
                print_success "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option"
                sleep 1
                ;;
        esac
    done
}

# ============================================
# START
# ============================================

clear_screen
main