#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import time
import itertools
import signal
import subprocess
import multiprocessing as mp
from multiprocessing import Pool, cpu_count
from typing import List, Tuple, Optional

# ============================================
# LIBRARY CHECKS
# ============================================
try:
    import pyzipper
    HAS_PYZIPPER = True
except ImportError:
    HAS_PYZIPPER = False

try:
    import zipfile
    HAS_ZIPFILE = True
except ImportError:
    HAS_ZIPFILE = False

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

try:
    from pptx import Presentation
    HAS_PPT = True
except ImportError:
    HAS_PPT = False

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
        self.last_update = 0

    def update(self, tested: int):
        self.tested = tested
        now = time.time()
        if now - self.last_update < 0.2 and tested < self.total:
            return
        self.last_update = now

        elapsed = now - self.start_time
        speed = tested / elapsed if elapsed > 0 else 0
        percent = min(100.0, (tested / self.total) * 100) if self.total > 0 else 0

        bar_length = 30
        filled = int(bar_length * percent / 100)
        bar = "\033[92m" + "█" * filled + "\033[0m" + "░" * (bar_length - filled)

        if speed > 0 and percent < 100:
            remaining = (self.total - tested) / speed
            mins, secs = divmod(int(remaining), 60)
            hrs, mins = divmod(mins, 60)
            eta = f"{hrs:02d}:{mins:02d}:{secs:02d}" if hrs > 0 else f"{mins:02d}:{secs:02d}"
        else:
            eta = "N/A"

        sys.stdout.write(f"\r[{bar}] {percent:.1f}% | {tested:,}/{self.total:,} | {speed:.0f}/s | ETA: {eta}")
        sys.stdout.flush()

    def finish(self):
        elapsed = time.time() - self.start_time
        speed = self.tested / elapsed if elapsed > 0 else 0
        sys.stdout.write(f"\r{' ' * 100}\r")
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
        self.progress: Optional[ProgressDisplay] = None

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

    # ---------- Password Test Methods ----------
    def test_password_zip(self, password: str) -> bool:
        pwd_bytes = password.encode('utf-8')
        if HAS_PYZIPPER:
            try:
                with pyzipper.AESZipFile(self.archive_file, 'r') as zf:
                    for info in zf.infolist():
                        if not info.filename.endswith('/'):
                            zf.read(info.filename, pwd=pwd_bytes)
                            return True
            except:
                pass
        if HAS_ZIPFILE:
            try:
                with zipfile.ZipFile(self.archive_file, 'r') as zf:
                    for info in zf.infolist():
                        if not info.filename.endswith('/'):
                            zf.read(info.filename, pwd=pwd_bytes)
                            return True
            except:
                pass
        return False

    def test_password_7z(self, password: str) -> bool:
        try:
            result = subprocess.run(
                ['7z', 't', f'-p{password}', self.archive_file, '-y'],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            return result.returncode == 0
        except:
            return False

    def test_password_rar(self, password: str) -> bool:
        try:
            result = subprocess.run(
                ['unrar', 't', f'-p{password}', self.archive_file],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
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
                    return reader.decrypt(password) in (1, 2)
        except:
            pass
        return False

    def test_password_excel(self, password: str) -> bool:
        if not HAS_EXCEL:
            return False
        try:
            if self.archive_file.lower().endswith('.xlsx'):
                openpyxl.load_workbook(self.archive_file, read_only=True, data_only=True)
                return True
            elif self.archive_file.lower().endswith('.xls'):
                import xlrd
                xlrd.open_workbook(self.archive_file, password=password)
                return True
        except:
            pass
        return False

    def test_password_powerpoint(self, password: str) -> bool:
        return self.test_password_7z(password)

    def test_password_word(self, password: str) -> bool:
        return self.test_password_7z(password)

    def test_password(self, password: str) -> bool:
        if self.archive_type in ("zip", "aes", "standard"):
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
        elif self.archive_type == "auto":
            if self.test_password_zip(password):
                self.archive_type = "zip"
                return True
            if self.test_password_7z(password):
                self.archive_type = "7z"
                return True
            if self.test_password_rar(password):
                self.archive_type = "rar"
                return True
            if self.test_password_pdf(password):
                self.archive_type = "pdf"
                return True
            if self.test_password_excel(password):
                self.archive_type = "excel"
                return True
            if self.test_password_powerpoint(password):
                self.archive_type = "powerpoint"
                return True
            if self.test_password_word(password):
                self.archive_type = "word"
                return True
        return False

    # ---------- Extraction ----------
    def extract_files(self, password: str) -> bool:
        try:
            import shutil
            if os.path.exists(self.output_dir):
                shutil.rmtree(self.output_dir)
            os.makedirs(self.output_dir, exist_ok=True)

            if self.archive_type in ("zip", "aes", "standard"):
                try:
                    with pyzipper.AESZipFile(self.archive_file, 'r') as zf:
                        zf.extractall(path=self.output_dir, pwd=password.encode())
                except:
                    with zipfile.ZipFile(self.archive_file, 'r') as zf:
                        zf.extractall(path=self.output_dir, pwd=password.encode())
                return True

            elif self.archive_type == "7z":
                result = subprocess.run(
                    ['7z', 'x', f'-p{password}', f'-o{self.output_dir}', self.archive_file, '-y'],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
                return result.returncode == 0

            elif self.archive_type == "rar":
                result = subprocess.run(
                    ['unrar', 'x', f'-p{password}', self.archive_file, f'{self.output_dir}/', '-y'],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
                return result.returncode == 0

            elif self.archive_type == "pdf":
                with open(self.archive_file, 'rb') as file:
                    reader = PyPDF2.PdfReader(file)
                    if reader.is_encrypted:
                        reader.decrypt(password)
                    writer = PyPDF2.PdfWriter()
                    for page in reader.pages:
                        writer.add_page(page)
                    out_path = os.path.join(self.output_dir, os.path.basename(self.archive_file))
                    with open(out_path, 'wb') as out:
                        writer.write(out)
                return True

            elif self.archive_type == "excel":
                if self.archive_file.lower().endswith('.xlsx'):
                    wb = openpyxl.load_workbook(self.archive_file, data_only=True)
                    out_path = os.path.join(self.output_dir, os.path.basename(self.archive_file))
                    wb.save(out_path)
                    return True
                elif self.archive_file.lower().endswith('.xls'):
                    shutil.copy2(self.archive_file, self.output_dir)
                    return True

            elif self.archive_type in ("powerpoint", "word"):
                result = subprocess.run(
                    ['7z', 'x', f'-p{password}', f'-o{self.output_dir}', self.archive_file, '-y'],
                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
                )
                return result.returncode == 0

            return False
        except Exception as e:
            print(f"\n[!] Extraction error: {e}")
            return False

    # ---------- Password Generation ----------
    def generate_all_passwords(self, charset: str, pattern: str) -> List[str]:
        char_sets = []
        lowercase = ''.join(sorted([c for c in charset if c.islower()]))
        uppercase = ''.join(sorted([c for c in charset if c.isupper()]))
        digits = ''.join(sorted([c for c in charset if c.isdigit()]))
        symbols = ''.join(sorted([c for c in charset if not c.isalnum()]))
        sorted_charset = lowercase + uppercase + digits + symbols

        for ch in pattern:
            if ch == '?':
                char_sets.append(sorted_charset)
            else:
                char_sets.append(ch)

        print(f"[*] Generating passwords...", end='', flush=True)
        passwords = [''.join(combo) for combo in itertools.product(*char_sets)]
        print(f" Done. ({len(passwords):,} combinations)")
        return passwords

    # ---------- Worker Function for Multiprocessing ----------
    @staticmethod
    def _worker_check_batch(batch_args):
        """
        Args: (cracker_instance, batch_of_passwords)
        Returns: (found_password, number_tested_in_batch)
        """
        cracker, passwords = batch_args
        for pwd in passwords:
            if cracker.test_password(pwd):
                return pwd, 1  # found, and we tested 1 (the found one)
        return None, len(passwords)  # not found, tested all in batch

    # ---------- Multiprocessing Attack ----------
    def _run_attack_multiprocess(self, passwords: List[str], num_processes: int):
        self.total = len(passwords)
        self.progress = ProgressDisplay(self.total)
        self.found = False
        self.password = ""
        tested_count = 0

        # Split into batches
        batch_size = max(100, self.total // (num_processes * 10))
        batches = []
        for i in range(0, self.total, batch_size):
            batch = passwords[i:i+batch_size]
            batches.append((self, batch))

        print(f"[*] Distributed across {num_processes} processes...")

        with Pool(processes=num_processes) as pool:
            try:
                # imap_unordered returns results as they complete
                for found_pwd, num_tested in pool.imap_unordered(self._worker_check_batch, batches):
                    tested_count += num_tested
                    self.progress.update(tested_count)

                    if found_pwd is not None:
                        self.found = True
                        self.password = found_pwd
                        pool.terminate()
                        break
            except KeyboardInterrupt:
                pool.terminate()
                pool.join()
                raise

        self.progress.update(tested_count)
        elapsed, speed = self.progress.finish()
        print()
        self.tested = tested_count
        return self.password, elapsed, speed

    # ---------- Public attack methods ----------
    def brute_force_multiprocess(self, charset: str, pattern: str, num_processes: int = None) -> Tuple[bool, str]:
        if num_processes is None:
            num_processes = cpu_count()
        num_processes = max(1, num_processes)

        passwords = self.generate_all_passwords(charset, pattern)

        # For very small keyspace, single process is faster
        if len(passwords) < 5000:
            num_processes = 1

        print(f"\033[96m[*] Starting brute force attack\033[0m")
        print(f"[*] Archive Type: {self.archive_type.upper()}")
        print(f"[*] Pattern: {pattern}")
        print(f"[*] Total combinations: {len(passwords):,}")
        print(f"[*] Using {num_processes} CPU cores\n")

        found_password, elapsed, speed = self._run_attack_multiprocess(passwords, num_processes)

        if found_password:
            self.found = True
            self.password = found_password
            return True, found_password
        else:
            if self.tested >= self.total:
                print("\033[93m[!] 100% complete - All passwords tested\033[0m")
            print("\033[91m[-] Password not found\033[0m")
            return False, ""

    def dictionary_attack_multiprocess(self, dict_file: str, num_processes: int = None) -> Tuple[bool, str]:
        if num_processes is None:
            num_processes = cpu_count()
        num_processes = max(1, num_processes)

        if not os.path.exists(dict_file):
            print(f"\033[91m[!] Dictionary file not found\033[0m")
            return False, ""

        with open(dict_file, 'r', encoding='utf-8', errors='ignore') as f:
            passwords = [line.strip() for line in f if line.strip()]
        self.total = len(passwords)

        if self.total < 10000:
            num_processes = 1

        print(f"\033[96m[*] Starting dictionary attack\033[0m")
        print(f"[*] Archive Type: {self.archive_type.upper()}")
        print(f"[*] Dictionary: {os.path.basename(dict_file)}")
        print(f"[*] Passwords: {self.total:,}")
        print(f"[*] Using {num_processes} CPU cores\n")

        found_password, elapsed, speed = self._run_attack_multiprocess(passwords, num_processes)

        if found_password:
            self.found = True
            self.password = found_password
            return True, found_password
        else:
            if self.tested >= self.total:
                print("\033[93m[!] 100% complete - All passwords tested\033[0m")
            print("\033[91m[-] Password not found in dictionary\033[0m")
            return False, ""


# ============================================
# MAIN
# ============================================
def main():
    def signal_handler(sig, frame):
        print("\n\033[93m[!] Stopped by user\033[0m")
        sys.exit(1)
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
    num_procs = int(os.environ.get("CRACKER_THREADS", cpu_count()))

    if mode == "brute" and len(sys.argv) >= 6:
        charset = sys.argv[4]
        pattern = sys.argv[5]
        success, password = cracker.brute_force_multiprocess(charset, pattern, num_procs)
    elif mode == "dict" and len(sys.argv) >= 5:
        dict_file = sys.argv[4]
        success, password = cracker.dictionary_attack_multiprocess(dict_file, num_procs)
    else:
        print("\033[91m[!] Invalid mode or arguments\033[0m")
        sys.exit(1)

    if success:
        elapsed = time.time() - cracker.progress.start_time
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
        sys.exit(1)


if __name__ == "__main__":
    mp.set_start_method('fork', force=True)
    main()