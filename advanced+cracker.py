#!/usr/bin/env python3

import sys
import pyzipper
import zipfile
import itertools
import threading
import time
import os
import signal
import subprocess  # <-- নতুন যোগ করা হয়েছে
from typing import List, Tuple

# ============================================
# LIBRARY CHECKS
# ============================================
try:
    import pyzipper
    HAS_PYZIPPER = True
except ImportError:
    HAS_PYZIPPER = False

# PDF support
try:
    import PyPDF2
    HAS_PDF = True
except ImportError:
    HAS_PDF = False

# Excel support
try:
    import openpyxl
    HAS_EXCEL = True
except ImportError:
    try:
        import xlrd
        HAS_EXCEL = True
    except ImportError:
        HAS_EXCEL = False

# PowerPoint support
try:
    from pptx import Presentation
    HAS_PPT = True
except ImportError:
    HAS_PPT = False

# Word support
try:
    import docx
    HAS_DOCX = True
except ImportError:
    HAS_DOCX = False

class ProgressDisplay:
    def __init__(self, total: int):
        self.total = total
        self.tested = 0
        self.start_time = time.time()
        self.running = True
        self.current_pass = ""
        self.speed_history = []
    
    def update(self, tested: int, current: str):
        self.tested = tested
        self.current_pass = current
        
        elapsed = time.time() - self.start_time
        speed = tested / elapsed if elapsed > 0 else 0
        
        self.speed_history.append(speed)
        if len(self.speed_history) > 10:
            self.speed_history.pop(0)
        avg_speed = sum(self.speed_history) / len(self.speed_history) if self.speed_history else speed
        
        percent = min(100.0, (tested / self.total) * 100) if self.total > 0 else 0
        
        bar_length = 40
        filled = int(bar_length * percent / 100)
        
        if percent < 30:
            bar_color = "\033[91m"
        elif percent < 70:
            bar_color = "\033[93m"
        else:
            bar_color = "\033[92m"
            
        bar_reset = "\033[0m"
        
        bar = bar_color + "█" * filled + bar_reset + "░" * (bar_length - filled)
        
        if avg_speed > 0 and percent < 100:
            remaining = (self.total - self.tested) / avg_speed
            hours = int(remaining // 3600)
            minutes = int((remaining % 3600) // 60)
            seconds = int(remaining % 60)
            if hours > 0:
                eta = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
            else:
                eta = f"{minutes:02d}:{seconds:02d}"
        else:
            eta = "N/A"
        
        sys.stdout.write(f"\r[{bar}] {percent:.1f}% | Tested: {self.tested:,} | Speed: {avg_speed:.0f}/s | ETA: {eta}")
        sys.stdout.flush()
    
    def finish(self):
        elapsed = time.time() - self.start_time
        speed = self.tested / elapsed if elapsed > 0 else 0
        sys.stdout.write(f"\r{' ' * 120}\r")
        sys.stdout.flush()
        return elapsed, speed

class ArchiveCracker:
    def __init__(self, archive_file: str, archive_type: str = "auto", output_dir: str = "extracted"):
        self.archive_file = archive_file
        self.archive_type = archive_type
        self.output_dir = output_dir
        self.found = False
        self.password = ""
        self.tested = 0
        self.total = 0
        self.progress = None
        self.completed = False
        
        if self.archive_type == "auto":
            ext = archive_file.lower()
            if ext.endswith('.zip'):
                self.archive_type = "zip"
            elif ext.endswith('.7z'):
                self.archive_type = "7z"
            elif ext.endswith('.rar'):
                self.archive_type = "rar"
            elif ext.endswith('.pdf'):
                self.archive_type = "pdf"
            elif ext.endswith('.xls') or ext.endswith('.xlsx'):
                self.archive_type = "excel"
            elif ext.endswith('.ppt') or ext.endswith('.pptx'):
                self.archive_type = "powerpoint"
            elif ext.endswith('.doc') or ext.endswith('.docx'):
                self.archive_type = "word"
            else:
                self.archive_type = "zip"
    
    def test_password_zip(self, password: str) -> bool:
        try:
            pwd_bytes = password.encode('utf-8')
            
            if HAS_PYZIPPER:
                try:
                    with pyzipper.AESZipFile(self.archive_file, 'r') as zf:
                        for info in zf.infolist():
                            if not info.filename.endswith('/'):
                                try:
                                    zf.read(info.filename, pwd=pwd_bytes)
                                    return True
                                except RuntimeError as e:
                                    if 'Bad password' in str(e):
                                        return False
                                    continue
                                except:
                                    continue
                except:
                    pass
            
            try:
                with zipfile.ZipFile(self.archive_file, 'r') as zf:
                    for info in zf.infolist():
                        if not info.filename.endswith('/'):
                            try:
                                zf.read(info.filename, pwd=pwd_bytes)
                                return True
                            except RuntimeError as e:
                                if 'Bad password' in str(e):
                                    return False
                                continue
                            except:
                                continue
            except RuntimeError as e:
                if 'Bad password' in str(e):
                    return False
            except:
                pass
                
        except Exception as e:
            pass
        
        return False
    
    def test_password_7z(self, password: str) -> bool:
        try:
            # os.system পরিবর্তে subprocess.run ব্যবহার করা হয়েছে
            result = subprocess.run(
                ['7z', 't', f'-p{password}', self.archive_file, '-y'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return result.returncode == 0
        except:
            return False
    
    def test_password_rar(self, password: str) -> bool:
        try:
            # os.system পরিবর্তে subprocess.run ব্যবহার করা হয়েছে
            result = subprocess.run(
                ['unrar', 't', f'-p{password}', self.archive_file],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return result.returncode == 0
        except:
            return False
    
    def test_password_pdf(self, password: str) -> bool:
        if not HAS_PDF:
            return False
        
        try:
            with open(self.archive_file, 'rb') as file:
                reader = PyPDF2.PdfReader(file)
                if reader.is_encrypted:
                    result = reader.decrypt(password)
                    return result == 1 or result == 2
        except Exception as e:
            pass
        
        return False
    
    def test_password_excel(self, password: str) -> bool:
        if not HAS_EXCEL:
            return False
        
        try:
            if self.archive_file.lower().endswith('.xlsx'):
                workbook = openpyxl.load_workbook(self.archive_file, read_only=True, data_only=True)
                return True
            elif self.archive_file.lower().endswith('.xls'):
                import xlrd
                workbook = xlrd.open_workbook(self.archive_file, password=password)
                return True
        except Exception as e:
            pass
        
        return False
    
    def test_password_powerpoint(self, password: str) -> bool:
        try:
            # os.system পরিবর্তে subprocess.run ব্যবহার করা হয়েছে
            result = subprocess.run(
                ['7z', 't', f'-p{password}', self.archive_file, '-y'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return result.returncode == 0
        except:
            return False
    
    def test_password_word(self, password: str) -> bool:
        try:
            # os.system পরিবর্তে subprocess.run ব্যবহার করা হয়েছে
            result = subprocess.run(
                ['7z', 't', f'-p{password}', self.archive_file, '-y'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
            return result.returncode == 0
        except:
            return False
    
    def test_password(self, password: str) -> bool:
        # First check based on specified archive type
        if self.archive_type == "zip" or self.archive_type == "aes" or self.archive_type == "standard":
            return self.test_password_zip(password)
        elif self.archive_type == "7z":
            return self.test_password_7z(password)
        elif self.archive_type == "rar":
            return self.test_password_rar(password)
        elif self.archive_type == "pdf":
            return self.test_password_pdf(password)
        elif self.archive_type == "excel":
            return self.test_password_excel(password)
        elif self.archive_type == "powerpoint":
            return self.test_password_powerpoint(password)
        elif self.archive_type == "word":
            return self.test_password_word(password)
        
        # Auto mode - try all formats
        if self.archive_type == "auto":
            # Try ZIP first
            if self.test_password_zip(password):
                self.archive_type = "zip"
                return True
            
            # Try 7Z
            if self.test_password_7z(password):
                self.archive_type = "7z"
                return True
            
            # Try RAR
            if self.test_password_rar(password):
                self.archive_type = "rar"
                return True
            
            # Try PDF
            if self.test_password_pdf(password):
                self.archive_type = "pdf"
                return True
            
            # Try Excel
            if self.test_password_excel(password):
                self.archive_type = "excel"
                return True
            
            # Try PowerPoint
            if self.test_password_powerpoint(password):
                self.archive_type = "powerpoint"
                return True
            
            # Try Word
            if self.test_password_word(password):
                self.archive_type = "word"
                return True
        
        return False
    
    def extract_files(self, password: str) -> bool:
        try:
            if os.path.exists(self.output_dir):
                import shutil
                shutil.rmtree(self.output_dir)
            os.makedirs(self.output_dir, exist_ok=True)
            
            if self.archive_type in ["zip", "aes", "standard"]:
                try:
                    with pyzipper.AESZipFile(self.archive_file, 'r') as zf:
                        zf.extractall(path=self.output_dir, pwd=password.encode())
                except:
                    with zipfile.ZipFile(self.archive_file, 'r') as zf:
                        zf.extractall(path=self.output_dir, pwd=password.encode())
                return True
                
            elif self.archive_type == "7z":
                # os.system পরিবর্তে subprocess.run ব্যবহার করা হয়েছে
                result = subprocess.run(
                    ['7z', 'x', f'-p{password}', f'-o{self.output_dir}', self.archive_file, '-y'],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                return result.returncode == 0
                
            elif self.archive_type == "rar":
                # os.system পরিবর্তে subprocess.run ব্যবহার করা হয়েছে
                result = subprocess.run(
                    ['unrar', 'x', f'-p{password}', self.archive_file, f'{self.output_dir}/', '-y'],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                return result.returncode == 0
            
            elif self.archive_type == "pdf":
                with open(self.archive_file, 'rb') as file:
                    reader = PyPDF2.PdfReader(file)
                    if reader.is_encrypted:
                        reader.decrypt(password)
                    
                    writer = PyPDF2.PdfWriter()
                    for page_num in range(len(reader.pages)):
                        writer.add_page(reader.pages[page_num])
                    
                    output_file = os.path.join(self.output_dir, os.path.basename(self.archive_file))
                    with open(output_file, 'wb') as out_file:
                        writer.write(out_file)
                    return True
            
            elif self.archive_type == "excel":
                if self.archive_file.lower().endswith('.xlsx'):
                    workbook = openpyxl.load_workbook(self.archive_file, data_only=True)
                    output_file = os.path.join(self.output_dir, os.path.basename(self.archive_file))
                    workbook.save(output_file)
                    return True
                elif self.archive_file.lower().endswith('.xls'):
                    import shutil
                    shutil.copy2(self.archive_file, self.output_dir)
                    return True
            
            elif self.archive_type in ["powerpoint", "word"]:
                # os.system পরিবর্তে subprocess.run ব্যবহার করা হয়েছে
                result = subprocess.run(
                    ['7z', 'x', f'-p{password}', f'-o{self.output_dir}', self.archive_file, '-y'],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
                return result.returncode == 0
            
            return False
        except Exception as e:
            print(f"\n[!] Extraction error: {e}")
            return False
    
    # ============================================
    # BRUTE FORCE - PRE-GENERATE ALL PASSWORDS
    # ============================================
    def generate_all_passwords(self, charset: str, pattern: str) -> List[str]:
        """Generate all possible passwords based on pattern"""
        char_sets = []
        
        # Sort charset: lowercase first (a-z), then uppercase (A-Z), then digits (0-9), then symbols
        lowercase = ''.join(sorted([c for c in charset if c.islower()]))
        uppercase = ''.join(sorted([c for c in charset if c.isupper()]))
        digits = ''.join(sorted([c for c in charset if c.isdigit()]))
        symbols = ''.join(sorted([c for c in charset if not c.isalnum()]))
        
        sorted_charset = lowercase + uppercase + digits + symbols
        
        for char in pattern:
            if char == '?':
                char_sets.append(sorted_charset)
            else:
                char_sets.append(char)
        
        # Generate all passwords
        passwords = []
        total = 1
        for cs in char_sets:
            if isinstance(cs, str) and len(cs) > 1:
                total *= len(cs)
        
        print(f"\n[*] Generating {total:,} passwords...")
        
        for combo in itertools.product(*char_sets):
            passwords.append(''.join(combo))
        
        return passwords
    
    # ============================================
    # BRUTE FORCE WITH PRE-GENERATED PASSWORDS
    # ============================================
    def brute_force(self, charset: str, pattern: str, max_threads: int = 4) -> Tuple[bool, str]:
        # Generate all passwords first
        passwords = self.generate_all_passwords(charset, pattern)
        self.total = len(passwords)
        self.progress = ProgressDisplay(self.total)
        self.completed = False
        
        print(f"\033[96m[*] Starting brute force attack\033[0m")
        print(f"[*] Archive Type: {self.archive_type.upper()}")
        print(f"[*] Pattern: {pattern}")
        print(f"[*] Total combinations: {self.total:,}")
        
        if self.total > 0:
            est_time = self.total / 1000
            if est_time > 3600:
                hours = int(est_time // 3600)
                minutes = int((est_time % 3600) // 60)
                print(f"[*] Estimated time: ~{hours}h {minutes}m")
            elif est_time > 60:
                minutes = int(est_time // 60)
                print(f"[*] Estimated time: ~{minutes} minutes")
            else:
                print(f"[*] Estimated time: ~{int(est_time)} seconds")
        print()
        
        def worker(start_idx, end_idx, result):
            try:
                for i in range(start_idx, min(end_idx, self.total)):
                    if self.found:
                        break
                    
                    password = passwords[i]
                    
                    with threading.Lock():
                        self.tested += 1
                        self.progress.update(self.tested, password)
                    
                    if self.test_password(password):
                        with threading.Lock():
                            if not self.found:
                                self.found = True
                                self.password = password
                                result[0] = password
                        break
            except Exception as e:
                pass
        
        threads = []
        result = [None]
        chunk_size = self.total // max_threads + 1
        
        # signal handler - immediate exit
        def signal_handler(sig, frame):
            print("\n\033[93m[!] Stopped by user\033[0m")
            os._exit(1)
        
        signal.signal(signal.SIGINT, signal_handler)
        
        for i in range(max_threads):
            start = i * chunk_size
            end = start + chunk_size
            t = threading.Thread(target=worker, args=(start, end, result))
            t.daemon = True
            threads.append(t)
            t.start()
        
        while any(t.is_alive() for t in threads) and not self.found:
            time.sleep(0.1)
            
            if self.tested >= self.total and not self.found:
                self.completed = True
                break
        
        elapsed, speed = self.progress.finish()
        print()
        
        if self.completed and not self.found:
            print("\033[93m[!] 100% complete - All passwords tested\033[0m")
            print("\033[91m[-] Password not found\033[0m")
        
        return self.found, self.password
    
    def dictionary_attack(self, dict_file: str, max_threads: int = 4) -> Tuple[bool, str]:
        if not os.path.exists(dict_file):
            print(f"\033[91m[!] Dictionary file not found\033[0m")
            return False, ""
        
        passwords = []
        try:
            with open(dict_file, 'r', encoding='utf-8', errors='ignore') as f:
                for line in f:
                    line = line.strip()
                    if line:
                        passwords.append(line)
        except:
            print(f"\033[91m[!] Cannot read dictionary file\033[0m")
            return False, ""
        
        total = len(passwords)
        self.total = total
        self.progress = ProgressDisplay(total)
        self.completed = False
        
        print(f"\033[96m[*] Starting dictionary attack\033[0m")
        print(f"[*] Archive Type: {self.archive_type.upper()}")
        print(f"[*] Dictionary: {os.path.basename(dict_file)}")
        print(f"[*] Passwords: {total:,}")
        print()
        
        def dict_worker(start_idx, end_idx, result):
            try:
                for i in range(start_idx, min(end_idx, total)):
                    if self.found:
                        break
                    
                    password = passwords[i]
                    
                    with threading.Lock():
                        self.tested += 1
                        self.progress.update(self.tested, password)
                    
                    if self.test_password(password):
                        with threading.Lock():
                            if not self.found:
                                self.found = True
                                self.password = password
                                result[0] = password
                        break
            except Exception as e:
                pass
        
        threads = []
        result = [None]
        chunk_size = total // max_threads + 1
        
        # signal handler - immediate exit
        def signal_handler(sig, frame):
            print("\n\033[93m[!] Stopped by user\033[0m")
            os._exit(1)
        
        signal.signal(signal.SIGINT, signal_handler)
        
        for i in range(max_threads):
            start = i * chunk_size
            end = start + chunk_size
            t = threading.Thread(target=dict_worker, args=(start, end, result))
            t.daemon = True
            threads.append(t)
            t.start()
        
        while any(t.is_alive() for t in threads) and not self.found:
            time.sleep(0.1)
            
            if self.tested >= self.total and not self.found:
                self.completed = True
                break
        
        elapsed, speed = self.progress.finish()
        print()
        
        if self.completed and not self.found:
            print("\033[93m[!] 100% complete - All passwords tested\033[0m")
            print("\033[91m[-] Password not found in dictionary\033[0m")
        
        return self.found, self.password

def main():
    # signal handler - immediate exit
    def signal_handler(sig, frame):
        print("\n\033[93m[!] Stopped by user\033[0m")
        os._exit(1)
    
    signal.signal(signal.SIGINT, signal_handler)
    
    if len(sys.argv) < 5:
        print("Usage: python3 advanced+cracker.py <mode> <archive> <type> <arg1> [arg2]")
        print("Modes: brute <archive> <type> <charset> <pattern>")
        print("       dict <archive> <type> <dictionary>")
        print("Types: auto, zip, aes, standard, 7z, rar, pdf, excel, powerpoint, word")
        sys.exit(1)
    
    mode = sys.argv[1]
    archive_file = sys.argv[2]
    archive_type = sys.argv[3]
    
    if not os.path.exists(archive_file):
        print(f"\033[91m[!] Archive file not found\033[0m")
        sys.exit(1)
    
    cracker = ArchiveCracker(archive_file, archive_type)
    
    if mode == "brute" and len(sys.argv) >= 6:
        charset = sys.argv[4]
        pattern = sys.argv[5]
        success, password = cracker.brute_force(charset, pattern, max_threads=4)
    elif mode == "dict" and len(sys.argv) >= 5:
        dict_file = sys.argv[4]
        success, password = cracker.dictionary_attack(dict_file, max_threads=4)
    else:
        print("\033[91m[!] Invalid mode or arguments\033[0m")
        sys.exit(1)
    
    elapsed = time.time() - cracker.progress.start_time
    
    if success:
        print(f"\n\033[92m[+] PASSWORD FOUND!\033[0m")
        print(f"\033[92m[+] Password: {password}\033[0m")
        print(f"[+] Archive Type: {cracker.archive_type.upper()}")
        print(f"[+] Tested: {cracker.tested:,} passwords")
        print(f"[+] Time: {elapsed:.2f} seconds")
        print(f"[+] Speed: {cracker.tested/elapsed:.0f} passwords/second")
        
        print(f"\n[*] Extracting files...")
        if cracker.extract_files(password):
            print(f"\033[92m[+] Files extracted to: {cracker.output_dir}\033[0m")
            
            if os.path.exists(cracker.output_dir):
                import glob
                files = glob.glob(os.path.join(cracker.output_dir, "**"), recursive=True)
                files = [f for f in files if os.path.isfile(f)]
                if files:
                    print(f"[+] Extracted {len(files)} files")
                    if len(files) <= 10:
                        for f in files[:10]:
                            size = os.path.getsize(f)
                            print(f"    {os.path.basename(f)} ({size} bytes)")
        else:
            print(f"\033[93m[!] Extraction failed\033[0m")
        
        with open("crack_result.txt", "w") as f:
            f.write(f"Password: {password}\n")
            f.write(f"File: {archive_file}\n")
            f.write(f"Type: {cracker.archive_type}\n")
            f.write(f"Tested: {cracker.tested}\n")
            f.write(f"Time: {elapsed:.2f}s\n")
            f.write(f"Speed: {cracker.tested/elapsed:.0f}/s\n")
        
        sys.exit(0)
    else:
        print(f"\n\033[91m[-] Password not found\033[0m")
        print(f"[-] Tested: {cracker.tested:,} passwords")
        print(f"[-] Time: {elapsed:.2f} seconds")
        print(f"[-] Speed: {cracker.tested/elapsed:.0f} passwords/second")
        sys.exit(1)

if __name__ == "__main__":
    main()
