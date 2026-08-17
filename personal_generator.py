#!/usr/bin/env python3
# personal_generator.py
# Standalone personal information password generator
# Usage: python3 personal_generator.py
# Reads personal_data.txt (see format below) and outputs personal_passwords.txt

import sys
import itertools
import re
import datetime

def generate_passwords_from_info(first_name, last_name, birth_day, birth_month, birth_year, 
                                 mobile, girlfriend, spouse, pet, city, fav_num, old_pwds, special_dates):
    
    passwords = set()
    
    # Clean and prepare data
    first = first_name.strip()
    last = last_name.strip()
    day = birth_day.strip()
    month = birth_month.strip()
    year = birth_year.strip()
    gf = girlfriend.strip()
    sp = spouse.strip()
    pt = pet.strip()
    ct = city.strip()
    fn = fav_num.strip()
    
    # Year variations
    year_full = year
    year_short = year[-2:] if len(year) >= 2 else ""
    
    # ============================================
    # MULTIPLE MOBILE NUMBERS SUPPORT
    # ============================================
    mobile_numbers = []
    if mobile.strip():
        # Split by comma and clean each number
        raw_numbers = [num.strip() for num in mobile.split(',') if num.strip()]
        for num in raw_numbers:
            # Remove any non-digit characters
            clean_num = ''.join(filter(str.isdigit, num))
            if clean_num:
                mobile_numbers.append(clean_num)
    
    # If no valid numbers found, add empty string
    if not mobile_numbers:
        mobile_numbers.append("")
    
    # Process EACH mobile number separately
    for mob_full in mobile_numbers:
        if mob_full:
            mob_last4 = mob_full[-4:] if len(mob_full) >= 4 else ""
            mob_last5 = mob_full[-5:] if len(mob_full) >= 5 else ""
            mob_last6 = mob_full[-6:] if len(mob_full) >= 6 else ""
            mob_first4 = mob_full[:4] if len(mob_full) >= 4 else ""
            mob_first5 = mob_full[:5] if len(mob_full) >= 5 else ""
            mob_first6 = mob_full[:6] if len(mob_full) >= 6 else ""
            mob_mid5 = mob_full[2:7] if len(mob_full) >= 7 else ""
            mob_last2 = mob_full[-2:] if len(mob_full) >= 2 else ""
            mob_first2 = mob_full[:2] if len(mob_full) >= 2 else ""
            mob_international = "+88" + mob_full if len(mob_full) > 0 else ""
            mob_international2 = "88" + mob_full if len(mob_full) > 0 else ""
            mob_last3 = mob_full[-3:] if len(mob_full) >= 3 else ""
            mob_last7 = mob_full[-7:] if len(mob_full) >= 7 else ""
            mob_last8 = mob_full[-8:] if len(mob_full) >= 8 else ""
        else:
            mob_last4 = mob_last5 = mob_last6 = mob_first4 = mob_first5 = mob_first6 = ""
            mob_mid5 = mob_last2 = mob_first2 = mob_international = mob_international2 = ""
            mob_last3 = mob_last7 = mob_last8 = ""
        
        # All possible components
        components = []
        if first: components.append(first)
        if last: components.append(last)
        if day: components.append(day)
        if month: components.append(month)
        if year_full: components.append(year_full)
        if year_short: components.append(year_short)
        if mob_full: components.append(mob_full)
        if mob_last4: components.append(mob_last4)
        if mob_last5: components.append(mob_last5)
        if mob_last6: components.append(mob_last6)
        if mob_first4: components.append(mob_first4)
        if mob_first5: components.append(mob_first5)
        if mob_first6: components.append(mob_first6)
        if mob_mid5: components.append(mob_mid5)
        if mob_last2: components.append(mob_last2)
        if mob_first2: components.append(mob_first2)
        if mob_international: components.append(mob_international)
        if mob_international2: components.append(mob_international2)
        if mob_last3: components.append(mob_last3)
        if mob_last7: components.append(mob_last7)
        if mob_last8: components.append(mob_last8)
        if gf: components.append(gf)
        if sp: components.append(sp)
        if pt: components.append(pt)
        if ct: components.append(ct)
        if fn: components.append(fn)
        
        # Add combined names
        if first and last:
            components.append(first + last)
            components.append(last + first)
            components.append(first + "." + last)
            components.append(first + "_" + last)
            components.append(first[0] + last)
            components.append(first + last[0])
        
        # Common suffixes and numbers
        common_suffixes = ['', '123', '1234', '12345', '123456', '!', '@', '#', '!@#', '!@#$']
        common_numbers = ['', '1', '12', '123', '1234', '007', '100', '200', '500', '1000']
        
        # PATTERN 1: Name + Year (Minhaz2008)
        if first and year_full:
            passwords.add(first + year_full)
            passwords.add(first.lower() + year_full)
            passwords.add(first.capitalize() + year_full)
            passwords.add(first + year_short)
            
            # With suffixes
            for suf in common_suffixes:
                passwords.add(first + year_full + suf)
                passwords.add(first.lower() + year_full + suf)
        
        # PATTERN 2: Name + Year + Extra (Minhaz2008uddin)
        if first and last and year_full:
            passwords.add(first + year_full + last)
            passwords.add(first + last + year_full)
            passwords.add(first.capitalize() + year_full + last.lower())
        
        # PATTERN 3: Full name + Year (Minhazuddin2008)
        if first and last and year_full:
            full_name = first + last
            passwords.add(full_name + year_full)
            passwords.add(full_name.lower() + year_full)
            passwords.add(full_name.capitalize() + year_full)
            
            # Variations
            passwords.add(first + last + year_short)
            passwords.add(first.capitalize() + last.capitalize() + year_full)
        
        # PATTERN 4: Name + Mobile (Sajim Islam01852288884) - FOR EACH MOBILE
        if first and mob_full:
            # With space
            passwords.add(first + " " + last + mob_full if last else first + mob_full)
            # Without space
            passwords.add(first + last + mob_full if last else first + mob_full)
            # Last digits only
            if mob_last6:
                passwords.add(first + mob_last6)
                passwords.add(first.lower() + mob_last6)
                passwords.add(first + last + mob_last6 if last else first + mob_last6)
            if mob_last5:
                passwords.add(first + mob_last5)
                passwords.add(first.lower() + mob_last5)
            if mob_last4:
                passwords.add(first + mob_last4)
                passwords.add(first + "123" + mob_last4)
                passwords.add(first + last + mob_last4 if last else first + mob_last4)
            # First digits only
            if mob_first4:
                passwords.add(first + mob_first4)
                passwords.add(first + last + mob_first4 if last else first + mob_first4)
            if mob_first5:
                passwords.add(first + mob_first5)
                passwords.add(first + last + mob_first5 if last else first + mob_first5)
            if mob_first6:
                passwords.add(first + mob_first6)
                passwords.add(first + last + mob_first6 if last else first + mob_first6)
        
        # PATTERN 5: Name + Common numbers (Sajim Islam123)
        if first:
            for num in common_numbers:
                if num:
                    passwords.add(first + " " + last + num if last else first + num)
                    passwords.add(first + last + num if last else first + num)
                    passwords.add(first.lower() + num)
                    passwords.add(first.capitalize() + num)
        
        # PATTERN 6: Name + Special char + numbers (Minhaz@2008)
        if first and year_full:
            special_chars = ['@', '_', '.', '-', '#', '!']
            for char in special_chars:
                passwords.add(first + char + year_full)
                passwords.add(first + char + year_short)
                passwords.add(first.lower() + char + year_full)
        
        # PATTERN 7: Reverse (2008Minhaz)
        if first and year_full:
            passwords.add(year_full + first)
            passwords.add(year_short + first)
            passwords.add(year_full + first.lower())
        
        # PATTERN 8: Name + Short numbers (Minhaz008)
        if first:
            for i in range(10, 1000, 1):
                if len(passwords) > 50000:
                    break
                passwords.add(first + str(i).zfill(3))
                passwords.add(first.lower() + str(i).zfill(3))
        
        # PATTERN 9: Name.Last (Minhaz.islam)
        if first and last:
            passwords.add(first + "." + last)
            passwords.add(first + "." + last.lower())
            passwords.add(first.lower() + "." + last.lower())
        
        # PATTERN 10: Namesurname + year (Minhazislam2008)
        if first and last and year_full:
            passwords.add(first + last + year_full)
            passwords.add(first.lower() + last.lower() + year_full)
            passwords.add(first + last + year_short)
        
        # PATTERN 11: Name + Multiple numbers (Minhaz123456)
        if first:
            for num in ['123', '1234', '12345', '123456', '1234567', '12345678']:
                passwords.add(first + num)
                passwords.add(first.lower() + num)
        
        # PATTERN 12: First name + Last name only
        if first and last:
            passwords.add(first + last)
            passwords.add(last + first)
            passwords.add(first.upper() + last.upper())
            passwords.add(first.capitalize() + last.capitalize())
        
        # PATTERN 13: Lowercase only (minhaz2008)
        if first and year_full:
            passwords.add(first.lower() + year_full)
            passwords.add(first.lower() + year_short)
        
        # PATTERN 14: Uppercase only (MINHAZ2008)
        if first and year_full:
            passwords.add(first.upper() + year_full)
            passwords.add(first.upper() + year_short)
        
        # PATTERN 15: Name + @ + year (Minhaz@2008)
        if first and year_full:
            passwords.add(first + "@" + year_full)
            passwords.add(first + "@" + year_short)
        
        # PATTERN 16: Name + _ + year (Minhaz_2008)
        if first and year_full:
            passwords.add(first + "_" + year_full)
            passwords.add(first + "_" + year_short)
        
        # PATTERN 17: Girlfriend related (MinhazPriya, MinhazLovePriya)
        if first and gf:
            passwords.add(first + gf)
            passwords.add(gf + first)
            passwords.add(first + "Love" + gf)
            passwords.add(first + "My" + gf)
            passwords.add(first + "&" + gf)
            passwords.add(first + gf + year_full if year_full else first + gf)
            
            # With numbers
            for num in common_suffixes:
                passwords.add(first + gf + num)
                passwords.add(first + "Love" + gf + num)
        
        # PATTERN 18: Spouse related
        if first and sp:
            passwords.add(first + sp)
            passwords.add(first + "Wife" + sp)
            passwords.add(first + "Husband" + sp)
            passwords.add(first + "&" + sp)
        
        # PATTERN 19: Pet related
        if first and pt:
            passwords.add(first + pt)
            passwords.add(pt + first)
            passwords.add(first + "My" + pt)
        
        # PATTERN 20: City related
        if first and ct:
            passwords.add(first + ct)
            passwords.add(ct + first)
            passwords.add(first + ct + year_full if year_full else first + ct)
        
        # PATTERN 21: Favorite number
        if first and fn:
            passwords.add(first + fn)
            passwords.add(fn + first)
            passwords.add(first + "No" + fn)
        
        # PATTERN 22: Name + Day + Month
        if first and day and month:
            passwords.add(first + day + month)
            passwords.add(first + month + day)
            passwords.add(first + day + month + year_short if year_short else first + day + month)
        
        # PATTERN 23: Initials + year (MI2008)
        if first and last and year_full:
            initials = first[0] + last[0]
            passwords.add(initials + year_full)
            passwords.add(initials.upper() + year_full)
            passwords.add(initials.lower() + year_full)
        
        # PATTERN 24: First 3 letters + year (Min2008)
        if first and year_full and len(first) >= 3:
            passwords.add(first[:3] + year_full)
            passwords.add(first[:3].capitalize() + year_full)
        
        # PATTERN 25: Last 3 letters + year (haz2008)
        if first and year_full and len(first) >= 3:
            passwords.add(first[-3:] + year_full)
            passwords.add(first[-3:].capitalize() + year_full)
        
        # PATTERN 26: Date combinations (DDMMYYYY)
        if day and month and year_full:
            passwords.add(day + month + year_full)
            passwords.add(year_full + month + day)
            if first:
                passwords.add(first + day + month + year_full)
                passwords.add(day + month + year_full + first)
        
        # PATTERN 27: Simple combinations (2 components)
        for i in range(len(components)):
            for j in range(len(components)):
                if i != j:
                    combo = components[i] + components[j]
                    if 4 <= len(combo) <= 20:
                        passwords.add(combo)
                        passwords.add(combo.lower())
                        passwords.add(combo.capitalize())
        
        # PATTERN 28: Add common suffixes to all passwords
        enhanced = set()
        for pwd in list(passwords):
            enhanced.add(pwd)
            for suf in ['!', '@', '#', '$', '123', '1234', '1', '0', '00', '000']:
                if len(pwd + suf) <= 20:
                    enhanced.add(pwd + suf)
        
        # ============================================
        # @ SYMBOL VARIATIONS - COMPLETE SET
        # ============================================
        
        # PATTERN 29: @ AT THE BEGINNING - ALL VARIATIONS
        if first:
            passwords.add("@" + first)
            passwords.add("@" + first.lower())
            passwords.add("@" + first.upper())
            passwords.add("@" + first.capitalize())
            
            if last:
                passwords.add("@" + first + last)
                passwords.add("@" + first.lower() + last.lower())
                passwords.add("@" + first.upper() + last.upper())
                passwords.add("@" + first.capitalize() + last.capitalize())
                
                if year_full:
                    passwords.add("@" + first + last + year_full)
                    passwords.add("@" + first + last + year_short)
                    passwords.add("@" + first.lower() + last.lower() + year_full)
                    passwords.add("@" + first.upper() + last.upper() + year_full)
                    passwords.add("@" + first + year_full + last)
                    passwords.add("@" + first + year_short + last)
                    passwords.add("@" + first.lower() + year_full + last.lower())
            
            if year_full:
                passwords.add("@" + first + year_full)
                passwords.add("@" + first + year_short)
                passwords.add("@" + first.lower() + year_full)
                passwords.add("@" + first.upper() + year_full)
        
        # PATTERN 30: @ AT THE END - ALL VARIATIONS
        if first:
            passwords.add(first + "@")
            passwords.add(first.lower() + "@")
            passwords.add(first.upper() + "@")
            
            if last:
                passwords.add(first + last + "@")
                passwords.add(first.lower() + last.lower() + "@")
                passwords.add(first.upper() + last.upper() + "@")
                
                if year_full:
                    passwords.add(first + last + year_full + "@")
                    passwords.add(first + last + year_short + "@")
                    passwords.add(first + year_full + last + "@")
                    passwords.add(first + year_short + last + "@")
            
            if year_full:
                passwords.add(first + year_full + "@")
                passwords.add(first + year_short + "@")
                passwords.add(first.lower() + year_full + "@")
        
        # PATTERN 31: @ IN THE MIDDLE - NAME@NAME
        if first and last:
            passwords.add(first + "@" + last)
            passwords.add(first + "@" + last.capitalize())
            passwords.add(first.lower() + "@" + last.lower())
            passwords.add(first.upper() + "@" + last.upper())
            passwords.add(first.capitalize() + "@" + last.capitalize())
        
        # PATTERN 32: @ IN THE MIDDLE - NAME@YEAR
        if first and year_full:
            passwords.add(first + "@" + year_full)
            passwords.add(first + "@" + year_short)
            passwords.add(first.lower() + "@" + year_full)
            passwords.add(first.upper() + "@" + year_full)
        
        # PATTERN 33: @ IN THE MIDDLE - YEAR@NAME
        if first and year_full:
            passwords.add(year_full + "@" + first)
            passwords.add(year_short + "@" + first)
            passwords.add(year_full + "@" + first.lower())
            passwords.add(year_full + "@" + first.upper())
        
        # PATTERN 34: @ IN THE MIDDLE - NAME@NAME@YEAR
        if first and last and year_full:
            passwords.add(first + "@" + last + "@" + year_full)
            passwords.add(first + "@" + last + "@" + year_short)
            passwords.add(first + "@" + year_full + "@" + last)
            passwords.add(first + "@" + year_short + "@" + last)
            passwords.add(year_full + "@" + first + "@" + last)
            passwords.add(year_short + "@" + first + "@" + last)
        
        # PATTERN 35: @ WITH MOBILE - FOR EACH MOBILE
        if first and mob_full:
            passwords.add(first + "@" + mob_full)
            passwords.add(first + "@" + mob_last6)
            passwords.add(first + "@" + mob_last4)
            passwords.add(first.lower() + "@" + mob_full)
            passwords.add(first + last + "@" + mob_full if last else first + "@" + mob_full)
            passwords.add(mob_full + "@" + first)
            passwords.add(mob_last6 + "@" + first)
            passwords.add(mob_last4 + "@" + first)
            passwords.add(mob_full + "@" + first + last if last else mob_full + "@" + first)
        
        # PATTERN 36: @ WITH GIRLFRIEND
        if first and gf:
            passwords.add(first + "@" + gf)
            passwords.add(gf + "@" + first)
            passwords.add(first.lower() + "@" + gf.lower())
            
            if year_full:
                passwords.add(first + "@" + gf + "@" + year_full)
                passwords.add(gf + "@" + first + "@" + year_short)
        
        # ============================================
        # $ SYMBOL VARIATIONS - COMPLETE SET
        # ============================================
        
        # PATTERN 37: $ AT THE BEGINNING
        if first:
            passwords.add("$" + first)
            passwords.add("$" + first.lower())
            
            if last:
                passwords.add("$" + first + last)
                
            if year_full:
                passwords.add("$" + first + year_full)
                passwords.add("$" + first + year_short)
        
        # PATTERN 38: $ AT THE END
        if first:
            passwords.add(first + "$")
            
            if last:
                passwords.add(first + last + "$")
                
            if year_full:
                passwords.add(first + year_full + "$")
        
        # PATTERN 39: $ IN THE MIDDLE
        if first and year_full:
            passwords.add(first + "$" + year_full)
            passwords.add(year_full + "$" + first)
        
        # ============================================
        # & SYMBOL VARIATIONS - COMPLETE SET
        # ============================================
        
        # PATTERN 40: & VARIATIONS
        if first and last:
            passwords.add(first + "&" + last)
            
            if year_full:
                passwords.add(first + "&" + year_full)
                passwords.add(first + "&" + last + "&" + year_full)
        
        # PATTERN 41: & WITH COUPLE NAMES
        if first and gf:
            passwords.add(first + "&" + gf)
            passwords.add(gf + "&" + first)
            
            if year_full:
                passwords.add(first + "&" + year_full + "&" + gf)
        
        # ============================================
        # ! SYMBOL VARIATIONS - COMPLETE SET
        # ============================================
        
        # PATTERN 42: ! AT THE BEGINNING
        if first:
            passwords.add("!" + first)
            
            if year_full:
                passwords.add("!" + first + year_full)
        
        # PATTERN 43: ! AT THE END
        if first:
            passwords.add(first + "!")
            
            if year_full:
                passwords.add(first + year_full + "!")
        
        # PATTERN 44: ! IN THE MIDDLE
        if first and year_full:
            passwords.add(first + "!" + year_full)
            passwords.add(year_full + "!" + first)
        
        # ============================================
        # # SYMBOL VARIATIONS - COMPLETE SET
        # ============================================
        
        # PATTERN 45: # AT THE BEGINNING
        if first:
            passwords.add("#" + first)
            
            if year_full:
                passwords.add("#" + first + year_full)
        
        # PATTERN 46: # AT THE END
        if first:
            passwords.add(first + "#")
            
            if year_full:
                passwords.add(first + year_full + "#")
        
        # PATTERN 47: # IN THE MIDDLE
        if first and year_full:
            passwords.add(first + "#" + year_full)
        
        # ============================================
        # % SYMBOL VARIATIONS
        # ============================================
        
        # PATTERN 48: % VARIATIONS
        if first and year_full:
            passwords.add(first + "%" + year_full)
            passwords.add("%" + first + year_full)
            passwords.add(first + year_full + "%")
        
        # ============================================
        # = SYMBOL VARIATIONS
        # ============================================
        
        # PATTERN 49: = VARIATIONS
        if first and year_full:
            passwords.add(first + "=" + year_full)
            passwords.add("=" + first + year_full)
        
        # ============================================
        # + SYMBOL VARIATIONS
        # ============================================
        
        # PATTERN 50: + VARIATIONS
        if first and year_full:
            passwords.add(first + "+" + year_full)
            passwords.add("+" + first + year_full)
        
        # ============================================
        # * SYMBOL VARIATIONS
        # ============================================
        
        # PATTERN 51: * VARIATIONS
        if first and year_full:
            passwords.add(first + "*" + year_full)
            passwords.add("*" + first + year_full)
        
        # ============================================
        # MIXED SYMBOLS COMBINATIONS
        # ============================================
        
        # PATTERN 52: @@ (DOUBLE AT)
        if first and year_full:
            passwords.add(first + "@@" + year_full)
            passwords.add(first + "@@" + year_short)
            passwords.add(year_full + "@@" + first)
            
            if last:
                passwords.add(first + last + "@@" + year_full)
        
        # PATTERN 53: !! VARIATIONS
        if first and year_full:
            passwords.add(first + "!!" + year_full)
            passwords.add("!!" + first + year_full)
        
        # PATTERN 54: ## VARIATIONS
        if first and year_full:
            passwords.add(first + "##" + year_full)
        
        # PATTERN 55: $$ VARIATIONS
        if first and year_full:
            passwords.add(first + "$$" + year_full)
        
        # PATTERN 56: && VARIATIONS
        if first and year_full:
            passwords.add(first + "&&" + year_full)
        
        # PATTERN 57: ++ VARIATIONS
        if first and year_full:
            passwords.add(first + "++" + year_full)
        
        # PATTERN 58: == VARIATIONS
        if first and year_full:
            passwords.add(first + "==" + year_full)
        
        # PATTERN 59: ~~ VARIATIONS
        if first and year_full:
            passwords.add(first + "~~" + year_full)
        
        # PATTERN 60: ^^ VARIATIONS
        if first and year_full:
            passwords.add(first + "^^" + year_full)
        
        # ============================================
        # MIXED SYMBOLS - MULTIPLE DIFFERENT SYMBOLS
        # ============================================
        
        # PATTERN 61: @ AND ! COMBINATION
        if first and year_full:
            passwords.add(first + "@" + year_full + "!")
            passwords.add(first + "@" + year_short + "!")
            passwords.add("@" + first + year_full + "!")
            passwords.add("!" + first + year_full + "@")
        
        # PATTERN 62: @ AND # COMBINATION
        if first and year_full:
            passwords.add(first + "@" + year_full + "#")
            passwords.add("#" + first + year_full + "@")
        
        # PATTERN 63: @ AND $ COMBINATION
        if first and year_full:
            passwords.add(first + "@" + year_full + "$")
        
        # PATTERN 64: ! AND # COMBINATION
        if first and year_full:
            passwords.add(first + "!" + year_full + "#")
        
        # ============================================
        # SYMBOL + NUMBER COMBOS
        # ============================================
        
        # PATTERN 65: SYMBOL + 123
        if first:
            passwords.add(first + "@" + "123")
            passwords.add(first + "@" + "1234")
            passwords.add(first + "!" + "123")
            passwords.add(first + "#" + "123")
            
            if year_full:
                passwords.add(first + year_full + "@" + "123")
                passwords.add("123" + "@" + first + year_full)
        
        # ============================================
        # SYMBOL BETWEEN NAME AND MOBILE - FOR EACH MOBILE
        # ============================================
        
        # PATTERN 66: ALL SYMBOLS BETWEEN NAME AND MOBILE
        if first and mob_full:
            for sym in ["@", "#", "!", "$", "%", "&", "*", "+", "=", "~", "^", "?"]:
                passwords.add(first + sym + mob_full)
                passwords.add(first + sym + mob_last6)
                passwords.add(first + sym + mob_last4)
                passwords.add(first + last + sym + mob_full if last else first + sym + mob_full)
                passwords.add(mob_full + sym + first)
                passwords.add(mob_last6 + sym + first)
                passwords.add(mob_full + sym + first + last if last else mob_full + sym + first)
        
        # ============================================
        # SYMBOL BETWEEN MOBILE AND YEAR - FOR EACH MOBILE
        # ============================================
        
        # PATTERN 67: SYMBOL BETWEEN MOBILE AND YEAR
        if mob_full and year_full:
            for sym in ["@", "#", "!", "$", "&", "*"]:
                passwords.add(mob_full + sym + year_full)
                passwords.add(mob_last6 + sym + year_short)
                passwords.add(year_full + sym + mob_full)
                passwords.add(year_short + sym + mob_last6)
        
        # ============================================
        # ALL SYMBOLS WITH NAME - COMPLETE SET
        # ============================================
        
        # PATTERN 68: ALL SYMBOLS - BEGINNING, END, MIDDLE
        if first:
            all_symbols = ["@", "$", "&", "!", "#", "%", "=", "+", "*", "~", "^", "?", "|", "/", "\\", "`", "'", "\"", ";", ":", ",", ".", "<", ">"]
            
            for sym in all_symbols:
                # Symbol at beginning
                passwords.add(sym + first)
                if last:
                    passwords.add(sym + first + last)
                if year_full:
                    passwords.add(sym + first + year_full)
                
                # Symbol at end
                passwords.add(first + sym)
                if last:
                    passwords.add(first + last + sym)
                if year_full:
                    passwords.add(first + year_full + sym)
                
                # Symbol in middle
                if last:
                    passwords.add(first + sym + last)
                if year_full:
                    passwords.add(first + sym + year_full)
                    passwords.add(year_full + sym + first)
                if mob_full:
                    passwords.add(first + sym + mob_last4)
                    passwords.add(first + sym + mob_last6)
                    passwords.add(mob_last4 + sym + first)
                    passwords.add(mob_last6 + sym + first)
        
        # ============================================
        # DOUBLE SYMBOLS - ALL COMBINATIONS
        # ============================================
        
        # PATTERN 69: DOUBLE SYMBOLS WITH NAME
        if first:
            double_symbols = ["@@", "!!", "##", "$$", "&&", "++", "==", "~~", "^^", "**", "??", "||", "//", "::", ";;", ",,", "..", "--", "__"]
            
            for sym in double_symbols:
                # Double symbol at beginning
                passwords.add(sym + first)
                # Double symbol at end
                passwords.add(first + sym)
                
                if year_full:
                    # Double symbol between
                    passwords.add(first + sym + year_full)
                    passwords.add(year_full + sym + first)
                
                if last:
                    passwords.add(first + sym + last)
                
                if mob_full:
                    passwords.add(first + sym + mob_last4)
                    passwords.add(mob_last4 + sym + first)
        
        # ============================================
        # TRIPLE SYMBOLS
        # ============================================
        
        # PATTERN 70: TRIPLE SYMBOLS
        if first:
            triple_symbols = ["@@@", "!!!", "###", "$$$", "&&&", "+++", "===", "~~~", "^^^", "***"]
            
            for sym in triple_symbols:
                passwords.add(sym + first)
                passwords.add(first + sym)
                
                if year_full:
                    passwords.add(first + sym + year_full)
        
        # ============================================
        # COMMON PASSWORD PATTERNS WITH SYMBOLS
        # ============================================
        
        # PATTERN 71: P@ssw0rd STYLE
        if first:
            passwords.add(first.replace('a', '@').replace('s', '$').replace('i', '1').replace('o', '0'))
            
            if year_full:
                pwd = first.replace('a', '@').replace('s', '$').replace('i', '1').replace('o', '0')
                passwords.add(pwd + year_full)
        
        # PATTERN 72: SYMBOL BETWEEN EACH LETTER (Rare but possible)
        if first and len(first) <= 6:
            syms = ['@', '!', '#', '$']
            for sym in syms:
                passwords.add(sym.join(first))
        
        # PATTERN 73: SYMBOL + NAME + REVERSE NAME
        if first:
            passwords.add("@" + first + first[::-1])
            if year_full:
                passwords.add("@" + first + first[::-1] + year_short)
        
        # ============================================
        # MOBILE NUMBER VARIATIONS WITH SYMBOLS - FOR EACH MOBILE
        # ============================================
        
        # PATTERN 74: MOBILE WITH ALL SYMBOLS
        if mob_full:
            all_symbols = ["@", "#", "!", "$", "%", "&", "*", "+", "=", "~", "^", "?"]
            for sym in all_symbols:
                passwords.add(sym + mob_full)
                passwords.add(mob_full + sym)
                passwords.add(sym + mob_last6)
                passwords.add(mob_last6 + sym)
                passwords.add(sym + mob_last4)
                passwords.add(mob_last4 + sym)
        
        # ============================================
        # YEAR VARIATIONS WITH SYMBOLS
        # ============================================
        
        # PATTERN 75: YEAR WITH ALL SYMBOLS
        if year_full:
            all_symbols = ["@", "#", "!", "$", "%", "&", "*", "+", "=", "~", "^", "?"]
            for sym in all_symbols:
                passwords.add(sym + year_full)
                passwords.add(year_full + sym)
                passwords.add(sym + year_short)
                passwords.add(year_short + sym)
        
        # ============================================
        # GIRLFRIEND/SPOUSE VARIATIONS WITH SYMBOLS
        # ============================================
        
        # PATTERN 76: GIRLFRIEND WITH SYMBOLS
        if gf:
            for sym in ["@", "&", "!", "#", "$"]:
                passwords.add(sym + gf)
                passwords.add(gf + sym)
                
                if first:
                    passwords.add(first + sym + gf + sym)
                    passwords.add(sym + first + sym + gf)
                
                if year_full:
                    passwords.add(gf + sym + year_full)
        
        # ============================================
        # ============================================
        # NEW PATTERNS 77-131 - ADDED FOR ENHANCED COVERAGE
        # ============================================
        # ============================================
        
        # PATTERN 77: Name + First 5 mobile + Last 4 mobile (Sajim018528884)
        if first and mob_full and mob_first5 and mob_last4:
            passwords.add(first + mob_first5 + mob_last4)
            passwords.add(first.lower() + mob_first5 + mob_last4)
            if last:
                passwords.add(first + last + mob_first5 + mob_last4)
        
        # PATTERN 78: Name + First 6 mobile + Last 4 mobile (Sajim0185228884)
        if first and mob_full and mob_first6 and mob_last4:
            passwords.add(first + mob_first6 + mob_last4)
            passwords.add(first.lower() + mob_first6 + mob_last4)
            if last:
                passwords.add(first + last + mob_first6 + mob_last4)
        
        # PATTERN 79: Name + Space + Last name + Mobile (Sajim Islam01852288884)
        if first and last and mob_full:
            passwords.add(first + " " + last + mob_full)
            passwords.add(first + " " + last + mob_last6)
            passwords.add(first + " " + last + mob_last4)
        
        # PATTERN 80: Name + Space + Last name + Space + Mobile (Sajim Islam 01852288884)
        if first and last and mob_full:
            passwords.add(first + " " + last + " " + mob_full)
            passwords.add(first + " " + last + " " + mob_last6)
            passwords.add(first + " " + last + " " + mob_last4)
        
        # PATTERN 81: International mobile formats (+8801852288884, 8801852288884)
        if mob_full:
            passwords.add("+88" + mob_full)
            passwords.add("88" + mob_full)
            passwords.add(first + "+88" + mob_full if first else "+88" + mob_full)
            passwords.add(first + "88" + mob_full if first else "88" + mob_full)
        
        # PATTERN 82: Only mobile first 5 digits (01852)
        if mob_first5:
            passwords.add(mob_first5)
            if first:
                passwords.add(first + mob_first5)
                passwords.add(mob_first5 + first)
        
        # PATTERN 83: Only mobile first 6 digits (018522)
        if mob_first6:
            passwords.add(mob_first6)
            if first:
                passwords.add(first + mob_first6)
                passwords.add(mob_first6 + first)
        
        # PATTERN 84: Only mobile middle 5 digits (52288)
        if mob_mid5:
            passwords.add(mob_mid5)
            if first:
                passwords.add(first + mob_mid5)
                passwords.add(mob_mid5 + first)
        
        # PATTERN 85: Name spelling variations (Minhaj, Minhaaz, Islamm, Sajem)
        if first:
            # Common spelling variations
            if first.lower() == "minhaz":
                passwords.add("Minhaj")
                passwords.add("Minhaaz")
                passwords.add("Minhazz")
                passwords.add("Minhazx")
            elif first.lower() == "sajim":
                passwords.add("Sajem")
                passwords.add("Sojim")
                passwords.add("Sajjum")
                passwords.add("Sajim")
            elif first.lower() == "islam":
                passwords.add("Islamm")
                passwords.add("Islaam")
                passwords.add("Islamb")
            elif first.lower() == "uddin":
                passwords.add("Udding")
                passwords.add("Uddin")
                passwords.add("Oddin")
        
        # PATTERN 86: Birth date with slash/dot/hyphen (15-08-2008, 15/08/2008, 15.08.2008)
        if day and month and year_full:
            passwords.add(day + "-" + month + "-" + year_full)
            passwords.add(day + "/" + month + "/" + year_full)
            passwords.add(day + "." + month + "." + year_full)
            passwords.add(day + "-" + month + "-" + year_short)
            passwords.add(day + "/" + month + "/" + year_short)
            passwords.add(day + "." + month + "." + year_short)
        
        # PATTERN 87: Birth date reversed (8002, 800215, 15088002)
        if day and month and year_full:
            passwords.add(year_full[::-1])
            passwords.add((day + month + year_full)[::-1])
            passwords.add((year_full + month + day)[::-1])
            if first:
                passwords.add(first + year_full[::-1])
        
        # PATTERN 88: Name reversed (zahniM, malsI)
        if first:
            passwords.add(first[::-1])
            if last:
                passwords.add(last[::-1])
                passwords.add(first[::-1] + last[::-1])
            if year_full:
                passwords.add(first[::-1] + year_full)
        
        # PATTERN 89: Name reversed + year (zahniM2008)
        if first and year_full:
            passwords.add(first[::-1] + year_full)
            passwords.add(first[::-1] + year_short)
        
        # PATTERN 90: Current year/age (2024, 2025, 24, 25)
        current_year = str(datetime.datetime.now().year)
        current_year_short = current_year[-2:]
        next_year = str(int(current_year) + 1)
        next_year_short = next_year[-2:]
        
        passwords.add(current_year)
        passwords.add(current_year_short)
        passwords.add(next_year)
        passwords.add(next_year_short)
        
        if first:
            passwords.add(first + current_year)
            passwords.add(first + current_year_short)
            passwords.add(first + next_year)
        
        # PATTERN 91: Name + current year (Sajim2024)
        if first:
            passwords.add(first + current_year)
            passwords.add(first + current_year_short)
            passwords.add(first + next_year)
        
        # PATTERN 92: My/আমার + Name (MyMinhaz, MySajim, আমারMinhaz)
        if first:
            passwords.add("My" + first)
            passwords.add("my" + first)
            passwords.add("MY" + first)
            passwords.add("আমার" + first)
            if last:
                passwords.add("My" + first + last)
        
        # PATTERN 93: Name + My/আমার (MinhazMy)
        if first:
            passwords.add(first + "My")
            passwords.add(first + "my")
        
        # PATTERN 94: First initials combination (SI, MI, SU, MU)
        if first and last:
            passwords.add(first[0] + last[0])
            passwords.add((first[0] + last[0]).upper())
            passwords.add((first[0] + last[0]).lower())
        
        # PATTERN 95: First initials + year (SI2008, MI08)
        if first and last and year_full:
            initials = first[0] + last[0]
            passwords.add(initials + year_full)
            passwords.add(initials + year_short)
            passwords.add(initials.upper() + year_full)
        
        # PATTERN 96: Pet name + Owner name (TomalMinhaz, SheraSajim)
        if pt and first:
            passwords.add(pt + first)
            passwords.add(pt.capitalize() + first.capitalize())
        
        # PATTERN 97: Owner name + Pet name (MinhazTomal)
        if first and pt:
            passwords.add(first + pt)
            passwords.add(first.capitalize() + pt.capitalize())
        
        # PATTERN 98: Favorite number + Name (7Minhaz)
        if fn and first:
            passwords.add(fn + first)
            passwords.add(fn + first.lower())
        
        # PATTERN 99: Name + Favorite number + Mobile (Minhaz701852)
        if first and fn and mob_first5:
            passwords.add(first + fn + mob_first5)
            passwords.add(first + fn + mob_last4)
        
        # PATTERN 100: Old password + Current year (oldpass2024)
        if old_pwds:
            old_list = [p.strip() for p in old_pwds.split(',') if p.strip()]
            for old in old_list:
                passwords.add(old + current_year)
                passwords.add(old + current_year_short)
        
        # PATTERN 101: Girlfriend + Mobile last 4 (Priya8884)
        if gf and mob_last4:
            passwords.add(gf + mob_last4)
            passwords.add(gf.lower() + mob_last4)
        
        # PATTERN 102: Girlfriend + Year (Priya2008)
        if gf and year_full:
            passwords.add(gf + year_full)
            passwords.add(gf + year_short)
        
        # PATTERN 103: Name + Girlfriend + Mobile (MinhazPriya01852)
        if first and gf and mob_first5:
            passwords.add(first + gf + mob_first5)
            passwords.add(first + gf + mob_last4)
        
        # PATTERN 104: City + Mobile (Dhaka01852)
        if ct and mob_first5:
            passwords.add(ct + mob_first5)
            passwords.add(ct + mob_last4)
        
        # PATTERN 105: Name + City + Year (MinhazDhaka2008)
        if first and ct and year_full:
            passwords.add(first + ct + year_full)
            passwords.add(first + ct + year_short)
        
        # PATTERN 106: Name + (Day+Month) (Minhaz1508)
        if first and day and month:
            passwords.add(first + day + month)
            passwords.add(first + month + day)
        
        # PATTERN 107: Birth month full + Year + Name (August2008Minhaz)
        if first and month and year_full:
            month_names = {
                "01": "January", "02": "February", "03": "March", "04": "April",
                "05": "May", "06": "June", "07": "July", "08": "August",
                "09": "September", "10": "October", "11": "November", "12": "December"
            }
            month_name = month_names.get(month, month)
            passwords.add(month_name + year_full + first)
            passwords.add(month_name[:3] + year_full + first)
        
        # PATTERN 108: First 3 letters + Last 3 letters (Minaz, Sajim)
        if first and len(first) >= 3:
            if last and len(last) >= 3:
                passwords.add(first[:3] + last[-3:])
                passwords.add(first[:3].capitalize() + last[-3:].capitalize())
        
        # PATTERN 109: First 2 letters + Last 2 letters (Mhz, Sjm)
        if first and len(first) >= 2:
            if last and len(last) >= 2:
                passwords.add(first[:2] + last[-2:])
                passwords.add(first[0] + last[0] + first[-1])
        
        # PATTERN 110: Two mobiles together (0185228888401311399766)
        if len(mobile_numbers) >= 2:
            passwords.add(mobile_numbers[0] + mobile_numbers[1])
            passwords.add(mobile_numbers[1] + mobile_numbers[0])
        
        # PATTERN 111: Mobile + Slash + Mobile (01852/01311)
        if len(mobile_numbers) >= 2:
            passwords.add(mobile_numbers[0][:5] + "/" + mobile_numbers[1][:5])
            passwords.add(mobile_numbers[0][-4:] + "/" + mobile_numbers[1][-4:])
        
        # PATTERN 112: Name + Space + Mobile first 5 (Sajim 01852)
        if first and mob_first5:
            passwords.add(first + " " + mob_first5)
            if last:
                passwords.add(first + " " + last + " " + mob_first5)
        
        # PATTERN 113: Initial + Dot + Full name (S.Sajim, M.Minhaz)
        if first:
            passwords.add(first[0] + "." + first)
            if last:
                passwords.add(first[0] + "." + first + last)
        
        # PATTERN 114: Name + Dot + Name (Sajim.Islam)
        if first and last:
            passwords.add(first + "." + last)
            passwords.add(first + "." + last.lower())
        
        # PATTERN 115: Name + Underscore + Name (Sajim_Islam)
        if first and last:
            passwords.add(first + "_" + last)
            passwords.add(first + "_" + last.lower())
        
        # PATTERN 116: Name + Dot + Mobile (Sajim.01852)
        if first and mob_first5:
            passwords.add(first + "." + mob_first5)
            passwords.add(first + "." + mob_last4)
        
        # PATTERN 117: Only Last name + Mobile (Islam01852)
        if last and mob_first5:
            passwords.add(last + mob_first5)
            passwords.add(last + mob_last4)
        
        # PATTERN 118: Only Last name + Year (Islam2008)
        if last and year_full:
            passwords.add(last + year_full)
            passwords.add(last + year_short)
        
        # PATTERN 119: Name + AT + Mobile (Sajim@01852)
        if first and mob_first5:
            passwords.add(first + "@" + mob_first5)
            passwords.add(first + "@" + mob_last4)
        
        # PATTERN 120: Mobile + AT + Name (01852@Sajim)
        if first and mob_first5:
            passwords.add(mob_first5 + "@" + first)
            passwords.add(mob_last4 + "@" + first)
        
        # PATTERN 121: Name letters separated by dots (S.A.J.I.M)
        if first:
            passwords.add(".".join(first))
            passwords.add(".".join(first.upper()))
            if last:
                passwords.add(".".join(first + last))
        
        # PATTERN 122: Name + Comma + Mobile (Sajim,01852)
        if first and mob_first5:
            passwords.add(first + "," + mob_first5)
            passwords.add(first + "," + mob_last4)
        
        # PATTERN 123: Birth date only day-month (15-08, 15/08, 15.08)
        if day and month:
            passwords.add(day + "-" + month)
            passwords.add(day + "/" + month)
            passwords.add(day + "." + month)
        
        # PATTERN 124: Birth date only month-year (08-2008, 08/2008, 08.2008)
        if month and year_full:
            passwords.add(month + "-" + year_full)
            passwords.add(month + "/" + year_full)
            passwords.add(month + "." + year_full)
            passwords.add(month + "-" + year_short)
        
        # PATTERN 125: Birth date only year-month (2008-08, 2008/08)
        if year_full and month:
            passwords.add(year_full + "-" + month)
            passwords.add(year_full + "/" + month)
        
        # PATTERN 126: Mobile last 2 digits only (84, 66)
        if mob_last2:
            passwords.add(mob_last2)
            if first:
                passwords.add(first + mob_last2)
        
        # PATTERN 127: Name + Mobile last 2 digits (Sajim84)
        if first and mob_last2:
            passwords.add(first + mob_last2)
            passwords.add(first.lower() + mob_last2)
        
        # PATTERN 128: Girlfriend + Mobile last 2 digits (Priya84)
        if gf and mob_last2:
            passwords.add(gf + mob_last2)
        
        # PATTERN 129: Pet + Mobile last 2 digits (Tomal84)
        if pt and mob_last2:
            passwords.add(pt + mob_last2)
        
        # PATTERN 130: Old password + Mobile last 2 digits (oldpass84)
        if old_pwds and mob_last2:
            old_list = [p.strip() for p in old_pwds.split(',') if p.strip()]
            for old in old_list:
                passwords.add(old + mob_last2)
        
        # PATTERN 131: First name initial + Last name initial + Mobile last 4 (SI8884)
        if first and last and mob_last4:
            passwords.add(first[0] + last[0] + mob_last4)
            passwords.add((first[0] + last[0]).upper() + mob_last4)
        
        # PATTERN 132: First 2 letters + Last 2 letters + Year (SaIs2008)
        if first and last and year_full and len(first) >= 2 and len(last) >= 2:
            passwords.add(first[:2] + last[:2] + year_full)
            passwords.add(first[:2] + last[:2] + year_short)
        
        # PATTERN 133: Name + Birth date with month name (Minhaz15August2008)
        if first and day and month and year_full:
            month_names = {
                "01": "January", "02": "February", "03": "March", "04": "April",
                "05": "May", "06": "June", "07": "July", "08": "August",
                "09": "September", "10": "October", "11": "November", "12": "December"
            }
            month_name = month_names.get(month, month)
            passwords.add(first + day + month_name + year_full)
            passwords.add(first + day + month_name[:3] + year_full)
        
        # PATTERN 134: Birth month full name + Year (August2008)
        if month and year_full:
            month_names = {
                "01": "January", "02": "February", "03": "March", "04": "April",
                "05": "May", "06": "June", "07": "July", "08": "August",
                "09": "September", "10": "October", "11": "November", "12": "December"
            }
            month_name = month_names.get(month, month)
            passwords.add(month_name + year_full)
            passwords.add(month_name[:3] + year_full)
        
        # PATTERN 135: Birth month short + Year (Aug2008)
        if month and year_full:
            month_short = {
                "01": "Jan", "02": "Feb", "03": "Mar", "04": "Apr",
                "05": "May", "06": "Jun", "07": "Jul", "08": "Aug",
                "09": "Sep", "10": "Oct", "11": "Nov", "12": "Dec"
            }
            month_short_name = month_short.get(month, month)
            passwords.add(month_short_name + year_full)
            passwords.add(month_short_name + year_short)
        
        # PATTERN 136: Name + Birth month (MinhazAugust)
        if first and month:
            month_names = {
                "01": "January", "02": "February", "03": "March", "04": "April",
                "05": "May", "06": "June", "07": "July", "08": "August",
                "09": "September", "10": "October", "11": "November", "12": "December"
            }
            month_name = month_names.get(month, month)
            passwords.add(first + month_name)
            passwords.add(first + month_name[:3])
        
        # PATTERN 137: Mobile + Birth month (01852August)
        if mob_first5 and month:
            month_names = {
                "01": "January", "02": "February", "03": "March", "04": "April",
                "05": "May", "06": "June", "07": "July", "08": "August",
                "09": "September", "10": "October", "11": "November", "12": "December"
            }
            month_name = month_names.get(month, month)
            passwords.add(mob_first5 + month_name)
            passwords.add(mob_last4 + month_name[:3])
        
        # PATTERN 138: Favorite number repeated (77, 1010, 55)
        if fn:
            passwords.add(fn + fn)
            passwords.add(fn + fn + fn)
        
        # PATTERN 139: Name + Favorite number repeated (Minhaz77)
        if first and fn:
            passwords.add(first + fn + fn)
        
        # PATTERN 140: Mobile first 5 + Mobile last 5 (0185288884)
        if mob_first5 and len(mob_full) >= 10:
            mob_last5 = mob_full[-5:]
            passwords.add(mob_first5 + mob_last5)
        
        # PATTERN 141: City + Birth year (Dhaka2008)
        if ct and year_full:
            passwords.add(ct + year_full)
            passwords.add(ct + year_short)
        
        # PATTERN 142: City + Mobile last 4 (Dhaka8884)
        if ct and mob_last4:
            passwords.add(ct + mob_last4)
        
        # PATTERN 143: Spouse + Mobile last 4 (Jerin8884)
        if sp and mob_last4:
            passwords.add(sp + mob_last4)
        
        # PATTERN 144: Name + Spouse + Year (MinhazJerin2008)
        if first and sp and year_full:
            passwords.add(first + sp + year_full)
            passwords.add(first + sp + year_short)
        
        # PATTERN 145: Pet name repeated (TomalTomal)
        if pt:
            passwords.add(pt + pt)
        
        # PATTERN 146: Name + Pet name repeated (MinhazTomalTomal)
        if first and pt:
            passwords.add(first + pt + pt)
        
        # PATTERN 147: Two mobiles last 4 together (88849976)
        if len(mobile_numbers) >= 2:
            mob1_last4 = mobile_numbers[0][-4:] if len(mobile_numbers[0]) >= 4 else ""
            mob2_last4 = mobile_numbers[1][-4:] if len(mobile_numbers[1]) >= 4 else ""
            if mob1_last4 and mob2_last4:
                passwords.add(mob1_last4 + mob2_last4)
        
        # PATTERN 148: Mobile last 4 + Dot + Mobile last 4 (8884.9976)
        if len(mobile_numbers) >= 2:
            mob1_last4 = mobile_numbers[0][-4:] if len(mobile_numbers[0]) >= 4 else ""
            mob2_last4 = mobile_numbers[1][-4:] if len(mobile_numbers[1]) >= 4 else ""
            if mob1_last4 and mob2_last4:
                passwords.add(mob1_last4 + "." + mob2_last4)
        
        # PATTERN 149: Name spelling variations - comprehensive
        if first:
            # Common typing mistakes and variations
            variations = []
            # Add extra last letter
            variations.append(first + first[-1])
            # Change last letter
            if first[-1] == 'a':
                variations.append(first[:-1] + 'e')
                variations.append(first[:-1] + 'o')
            elif first[-1] == 'm':
                variations.append(first[:-1] + 'n')
                variations.append(first + 'm')
            elif first[-1] == 'z':
                variations.append(first[:-1] + 'j')
                variations.append(first + 'z')
            
            for var in variations:
                passwords.add(var)
                if year_full:
                    passwords.add(var + year_full)
                if mob_last4:
                    passwords.add(var + mob_last4)
        
        # PATTERN 150: Year + Name + Mobile (2008Minhaz01852)
        if first and year_full and mob_first5:
            passwords.add(year_full + first + mob_first5)
            passwords.add(year_short + first + mob_last4)
        
        # PATTERN 151: Mobile half + Name + Mobile half (01852Minhaz8884)
        if first and mob_first5 and mob_last4:
            passwords.add(mob_first5 + first + mob_last4)
            passwords.add(mob_last4 + first + mob_first5)
        
        # PATTERN 152: Name + (Year-1) + (Year+1) (Minhaz20072009)
        if first and year_full and year_full.isdigit():
            year_int = int(year_full)
            prev_year = str(year_int - 1)
            next_year = str(year_int + 1)
            passwords.add(first + prev_year + next_year)
        
        # PATTERN 153: Mobile last 4 + Name first 4 + Mobile first 4 (8884Minh0185)
        if first and len(first) >= 4 and mob_last4 and mob_first4:
            passwords.add(mob_last4 + first[:4] + mob_first4)
        
        # PATTERN 154: City + Pet + Mobile last 4 (DhakaTomal8884)
        if ct and pt and mob_last4:
            passwords.add(ct + pt + mob_last4)
        
        # PATTERN 155: Name + Girlfriend + Name (MinhazPriyaMinhaz)
        if first and gf:
            passwords.add(first + gf + first)
        
        # PATTERN 156: Birth date + Mobile + Birth date (150820180185221508)
        if day and month and year_full and mob_full:
            passwords.add(day + month + year_full + mob_full + day + month)
        
        # PATTERN 157: Favorite number + Name + Favorite number (7Minhaz7)
        if fn and first:
            passwords.add(fn + first + fn)
        
        # PATTERN 158: Mobile first 2 + Name + Mobile last 2 (01Minhaz84)
        if mob_first2 and first and mob_last2:
            passwords.add(mob_first2 + first + mob_last2)
        
        # PATTERN 159: Name spelling variation + Year variation (Minhaj2007)
        if first and year_full and year_full.isdigit():
            year_int = int(year_full)
            if first.lower() == "minhaz":
                passwords.add("Minhaj" + str(year_int - 1))
                passwords.add("Minhaj" + str(year_int + 1))
        
        # PATTERN 160: Pet + City + Name (TomalDhakaMinhaz)
        if pt and ct and first:
            passwords.add(pt + ct + first)
        
        # PATTERN 161: Mobile last 4 + Birth day + Birth month (88841508)
        if mob_last4 and day and month:
            passwords.add(mob_last4 + day + month)
        
        # PATTERN 162: First 2 + Last 2 + Mobile last 2 + Year last 2 (MiUd8408)
        if first and last and len(first) >= 2 and len(last) >= 2 and mob_last2 and year_short:
            passwords.add(first[:2] + last[:2] + mob_last2 + year_short)
        
        # PATTERN 163: Girlfriend spelling variation + Name spelling variation (PriyaMinhaj)
        if gf and first:
            if gf.lower() == "priya":
                passwords.add("Priya" + "Minhaj")
            elif gf.lower() == "nishi":
                passwords.add("Nishi" + "Sajem")
        
        # PATTERN 164: City last 3 + Mobile last 3 + Year last 3 (aka884008)
        if ct and len(ct) >= 3 and mob_last3 and len(year_full) >= 3:
            passwords.add(ct[-3:] + mob_last3 + year_full[-3:])
        
        # PATTERN 165: Old password with one digit changed
        if old_pwds and year_full and year_full.isdigit():
            old_list = [p.strip() for p in old_pwds.split(',') if p.strip()]
            year_int = int(year_full)
            for old in old_list:
                passwords.add(old.replace(year_full, str(year_int + 1)))
                passwords.add(old.replace(year_full, str(year_int - 1)))
        
        # PATTERN 166: Name + Father's name part (if available in special_dates)
        if first and special_dates:
            # Assuming father's name might be in special_dates
            father_parts = special_dates.strip().split()
            for part in father_parts:
                if len(part) > 2:
                    passwords.add(first + part)
                    passwords.add(part + first)
        
        # PATTERN 167: Mother's name part + Name
        if first and special_dates:
            mother_parts = special_dates.strip().split()
            for part in mother_parts[::-1]:
                if len(part) > 2:
                    passwords.add(part + first)
        
        # PATTERN 168: Sibling birth year + Own birth year
        if year_full and special_dates:
            # Check if special_dates contains another year
            years = re.findall(r'\b(19|20)\d{2}\b', special_dates)
            for yr in years:
                if yr != year_full:
                    passwords.add(yr + year_full)
                    passwords.add(year_full + yr)
        
        # PATTERN 169: Roll/ID number + Name (if in special_dates)
        if first and special_dates:
            numbers = re.findall(r'\b\d{2,6}\b', special_dates)
            for num in numbers:
                if len(num) <= 6 and not num.startswith('19') and not num.startswith('20'):
                    passwords.add(num + first)
                    passwords.add(first + num)
        
        # PATTERN 170: Favorite player jersey number + Name
        if first and fn:
            # Common jersey numbers
            jersey_numbers = ['7', '10', '9', '11', '8', '5', '15', '23', '45']
            for num in jersey_numbers:
                if fn == num or not fn:
                    passwords.add(num + first)
        
        # PATTERN 171: Current age + Name + Birth year
        if first and year_full and year_full.isdigit():
            year_int = int(year_full)
            current_year_int = int(current_year)
            age = current_year_int - year_int
            if 1 <= age <= 100:
                passwords.add(str(age) + first + year_full)
        
        # PATTERN 172: Wedding date/Special date + Name
        if first and special_dates:
            dates = re.findall(r'\b\d{2,4}[-/.]?\d{2}[-/.]?\d{2,4}\b', special_dates)
            for date in dates:
                clean_date = ''.join(filter(str.isdigit, date))
                if len(clean_date) >= 6:
                    passwords.add(clean_date + first)
                    passwords.add(first + clean_date)
        
        # PATTERN 173: Child name + Own name
        if first and special_dates:
            words = special_dates.strip().split()
            for word in words:
                if word[0].isupper() and len(word) > 2 and word.lower() != first.lower():
                    passwords.add(word + first)
                    passwords.add(first + word)
        
        # PATTERN 174: Name + Job joining year
        if first and special_dates:
            years = re.findall(r'\b(19|20)\d{2}\b', special_dates)
            for yr in years:
                if yr != year_full:
                    passwords.add(first + yr)
        
        # PATTERN 175: Mobile number pattern (odd/even digits)
        if mob_full:
            # Take odd position digits
            odd_digits = ''.join([mob_full[i] for i in range(len(mob_full)) if i % 2 == 0])
            # Take even position digits
            even_digits = ''.join([mob_full[i] for i in range(len(mob_full)) if i % 2 == 1])
            if len(odd_digits) >= 4:
                passwords.add(odd_digits)
                if first:
                    passwords.add(first + odd_digits)
            if len(even_digits) >= 4:
                passwords.add(even_digits)
                if first:
                    passwords.add(first + even_digits)
        
        # ============================================
        # FINAL: Add all enhanced passwords
        # ============================================
        
        # Add all generated passwords to enhanced set
        for pwd in list(passwords):
            enhanced.add(pwd)
    
    # Add old passwords if any
    if old_pwds:
        old_list = [p.strip() for p in old_pwds.split(',') if p.strip()]
        for old in old_list:
            enhanced.add(old)
    
    return sorted(enhanced, key=lambda x: (len(x), x))

if __name__ == "__main__":
    # Read from file
    try:
        with open("personal_data.txt", "r") as f:
            lines = [line.strip() for line in f.readlines()]
        
        if len(lines) >= 13:
            first_name = lines[0]
            last_name = lines[1]
            birth_day = lines[2]
            birth_month = lines[3]
            birth_year = lines[4]
            mobile = lines[5]
            girlfriend = lines[6]
            spouse = lines[7]
            pet = lines[8]
            city = lines[9]
            fav_num = lines[10]
            old_pwds = lines[11]
            special_dates = lines[12] if len(lines) > 12 else ""
        else:
            print("Error: Insufficient data in personal_data.txt. Need at least 13 lines.")
            sys.exit(1)
        
        passwords = generate_passwords_from_info(
            first_name, last_name, birth_day, birth_month, birth_year,
            mobile, girlfriend, spouse, pet, city, fav_num, old_pwds, special_dates
        )
        
        with open("personal_passwords.txt", "w") as f:
            for pwd in passwords:
                f.write(pwd + "\n")
        
        print(f"Generated {len(passwords)} passwords")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)