const TEXT_LIMIT: usize = 32;
const PAD: usize = 5;
const KEY_LIMIT: usize = 4;

struct Encoder {
    text: [u8; TEXT_LIMIT + PAD],
    length: u8,
    primary: [u8; KEY_LIMIT],
    secondary: [u8; KEY_LIMIT],
    primary_len: u8,
    secondary_len: u8,
    alternate_seen: bool,
}

impl Encoder {
    fn at(&self, index: i32) -> u8 {
        if index >= 0 && (index as usize) < self.text.len() { self.text[index as usize] } else { b' ' }
    }

    fn has(&self, index: i32, token: &[u8]) -> bool {
        if index < 0 { return false; }
        let start = index as usize;
        start + token.len() <= self.text.len() && self.text[start..start + token.len()] == *token
    }

    fn vowel(&self, index: i32) -> bool {
        index >= 0 && index < self.length as i32 && b"AEIOUY".contains(&self.at(index))
    }

    fn slavo_germanic(&self) -> bool {
        (0..self.length as i32).any(|i| self.at(i) == b'W' || self.at(i) == b'K' ||
            self.has(i, b"CZ") || self.has(i, b"WITZ"))
    }

    fn append(target: &mut [u8; KEY_LIMIT], size: &mut u8, fragment: &[u8]) {
        for &byte in fragment {
            if *size as usize == KEY_LIMIT { break; }
            target[*size as usize] = byte;
            *size += 1;
        }
    }

    fn emit(&mut self, main: &[u8], alternate: Option<&[u8]>) {
        Self::append(&mut self.primary, &mut self.primary_len, main);
        match alternate {
            None => Self::append(&mut self.secondary, &mut self.secondary_len, main),
            Some(other) if !other.is_empty() => {
                self.alternate_seen = true;
                if other[0] != b' ' { Self::append(&mut self.secondary, &mut self.secondary_len, other); }
            }
            Some(_) if !main.is_empty() && main[0] != b' ' => {
                Self::append(&mut self.secondary, &mut self.secondary_len, main);
            }
            Some(_) => {}
        }
    }

    fn c_rule(&mut self, i: i32) -> i32 {
        if i > 1 && !self.vowel(i - 2) && self.has(i - 1, b"ACH") && self.at(i + 2) != b'I' &&
            (self.at(i + 2) != b'E' || self.has(i - 2, b"BACHER") || self.has(i - 2, b"MACHER")) {
            self.emit(b"K", None); return i + 2;
        }
        if i == 0 && self.has(i, b"CAESAR") { self.emit(b"S", None); return i + 2; }
        if self.has(i, b"CHIA") { self.emit(b"K", None); return i + 2; }
        if self.has(i, b"CH") {
            if i > 0 && self.has(i, b"CHAE") { self.emit(b"K", Some(b"X")); return i + 2; }
            if i == 0 && (self.has(i + 1, b"HARAC") || self.has(i + 1, b"HARIS") ||
                self.has(i + 1, b"HOR") || self.has(i + 1, b"HYM") || self.has(i + 1, b"HIA") ||
                self.has(i + 1, b"HEM")) && !self.has(0, b"CHORE") {
                self.emit(b"K", None); return i + 2;
            }
            let hard = self.has(0, b"VAN ") || self.has(0, b"VON ") || self.has(0, b"SCH") ||
                self.has(i - 2, b"ORCHES") || self.has(i - 2, b"ARCHIT") || self.has(i - 2, b"ORCHID") ||
                self.at(i + 2) == b'T' || self.at(i + 2) == b'S' ||
                ((b"AOUE".contains(&self.at(i - 1)) || i == 0) &&
                 b"LRNMBHFVW ".contains(&self.at(i + 2)));
            if hard { self.emit(b"K", None); }
            else if i > 0 {
                if self.has(0, b"MC") { self.emit(b"K", None); }
                else { self.emit(b"X", Some(b"K")); }
            } else { self.emit(b"X", None); }
            return i + 2;
        }
        if self.has(i, b"CZ") && !self.has(i - 2, b"WICZ") { self.emit(b"S", Some(b"X")); return i + 2; }
        if self.has(i + 1, b"CIA") { self.emit(b"X", None); return i + 3; }
        if self.has(i, b"CC") && !(i == 1 && self.at(0) == b'M') {
            if (b"IEH".contains(&self.at(i + 2))) && !self.has(i + 2, b"HU") {
                if (i == 1 && self.at(i - 1) == b'A') || self.has(i - 1, b"UCCEE") || self.has(i - 1, b"UCCES") {
                    self.emit(b"KS", None);
                } else { self.emit(b"X", None); }
                return i + 3;
            }
            self.emit(b"K", None); return i + 2;
        }
        if self.has(i, b"CK") || self.has(i, b"CG") || self.has(i, b"CQ") { self.emit(b"K", None); return i + 2; }
        if self.has(i, b"CI") || self.has(i, b"CE") || self.has(i, b"CY") {
            if self.has(i, b"CIO") || self.has(i, b"CIE") || self.has(i, b"CIA") { self.emit(b"S", Some(b"X")); }
            else { self.emit(b"S", None); }
            return i + 2;
        }
        self.emit(b"K", None);
        if self.has(i + 1, b" C") || self.has(i + 1, b" Q") || self.has(i + 1, b" G") { return i + 3; }
        if b"CKQ".contains(&self.at(i + 1)) && !self.has(i + 1, b"CE") && !self.has(i + 1, b"CI") { return i + 2; }
        i + 1
    }

    fn g_rule(&mut self, i: i32, slavo: bool) -> i32 {
        if self.at(i + 1) == b'H' {
            if i > 0 && !self.vowel(i - 1) { self.emit(b"K", None); return i + 2; }
            if i == 0 { self.emit(if self.at(i + 2) == b'I' { b"J" } else { b"K" }, None); return i + 2; }
            let silent = (i > 1 && b"BHD".contains(&self.at(i - 2))) ||
                (i > 2 && b"BHD".contains(&self.at(i - 3))) ||
                (i > 3 && b"BH".contains(&self.at(i - 4)));
            if silent { return i + 2; }
            if i > 2 && self.at(i - 1) == b'U' && b"CGLRT".contains(&self.at(i - 3)) { self.emit(b"F", None); }
            else if i > 0 && self.at(i - 1) != b'I' { self.emit(b"K", None); }
            return i + 2;
        }
        if self.at(i + 1) == b'N' {
            if i == 1 && self.vowel(0) && !slavo { self.emit(b"KN", Some(b"N")); }
            else if !self.has(i + 2, b"EY") && self.at(i + 1) != b'Y' && !slavo { self.emit(b"N", Some(b"KN")); }
            else { self.emit(b"KN", None); }
            return i + 2;
        }
        if self.has(i + 1, b"LI") && !slavo { self.emit(b"KL", Some(b"L")); return i + 2; }
        if i == 0 && (self.at(i + 1) == b'Y' || self.has(i + 1, b"ES") || self.has(i + 1, b"EP") ||
            self.has(i + 1, b"EB") || self.has(i + 1, b"EL") || self.has(i + 1, b"EY") ||
            self.has(i + 1, b"IB") || self.has(i + 1, b"IL") || self.has(i + 1, b"IN") ||
            self.has(i + 1, b"IE") || self.has(i + 1, b"EI") || self.has(i + 1, b"ER")) {
            self.emit(b"K", Some(b"J")); return i + 2;
        }
        if (self.has(i + 1, b"ER") || self.at(i + 1) == b'Y') && !self.has(0, b"DANGER") &&
            !self.has(0, b"RANGER") && !self.has(0, b"MANGER") && self.at(i - 1) != b'E' &&
            self.at(i - 1) != b'I' && !self.has(i - 1, b"RGY") && !self.has(i - 1, b"OGY") {
            self.emit(b"K", Some(b"J")); return i + 2;
        }
        if b"EIY".contains(&self.at(i + 1)) || self.has(i - 1, b"AGGI") || self.has(i - 1, b"OGGI") {
            if self.has(0, b"VAN ") || self.has(0, b"VON ") || self.has(0, b"SCH") || self.has(i + 1, b"ET") {
                self.emit(b"K", None);
            } else if self.has(i + 1, b"IER ") { self.emit(b"J", None); }
            else { self.emit(b"J", Some(b"K")); }
            return i + 2;
        }
        self.emit(b"K", None);
        i + if self.at(i + 1) == b'G' { 2 } else { 1 }
    }

    fn j_rule(&mut self, i: i32, slavo: bool) -> i32 {
        if self.has(i, b"JOSE") || self.has(0, b"SAN ") {
            if (i == 0 && self.at(i + 4) == b' ') || self.has(0, b"SAN ") { self.emit(b"H", None); }
            else { self.emit(b"J", Some(b"H")); }
            return i + 1;
        }
        if i == 0 { self.emit(b"J", Some(b"A")); }
        else if self.vowel(i - 1) && !slavo && b"AO".contains(&self.at(i + 1)) { self.emit(b"J", Some(b"H")); }
        else if i == self.length as i32 - 1 { self.emit(b"J", Some(b" ")); }
        else if !b"LTKSNMBZ".contains(&self.at(i + 1)) && !b"SKL".contains(&self.at(i - 1)) { self.emit(b"J", None); }
        i + if self.at(i + 1) == b'J' { 2 } else { 1 }
    }

    fn l_rule(&mut self, i: i32) -> i32 {
        if self.at(i + 1) != b'L' { self.emit(b"L", None); return i + 1; }
        let spanish = (i == self.length as i32 - 3 &&
            (self.has(i - 1, b"ILLO") || self.has(i - 1, b"ILLA") || self.has(i - 1, b"ALLE"))) ||
            ((self.has(self.length as i32 - 3, b"AS") || self.has(self.length as i32 - 3, b"OS") ||
              self.at(self.length as i32 - 1) == b'A' || self.at(self.length as i32 - 1) == b'O') && self.has(i - 1, b"ALLE"));
        if spanish { self.emit(b"L", Some(b" ")); } else { self.emit(b"L", None); }
        i + 2
    }

    fn s_rule(&mut self, i: i32, slavo: bool) -> i32 {
        if self.has(i - 1, b"ISL") || self.has(i - 1, b"YSL") { return i + 1; }
        if i == 0 && self.has(i, b"SUGAR") { self.emit(b"X", Some(b"S")); return i + 1; }
        if self.has(i, b"SH") {
            if self.has(i + 1, b"HEIM") || self.has(i + 1, b"HOEK") || self.has(i + 1, b"HOLM") || self.has(i + 1, b"HOLZ") { self.emit(b"S", None); }
            else { self.emit(b"X", None); }
            return i + 2;
        }
        if self.has(i, b"SIO") || self.has(i, b"SIA") || self.has(i, b"SIAN") {
            if !slavo { self.emit(b"S", Some(b"X")); } else { self.emit(b"S", None); }
            return i + 3;
        }
        if (i == 0 && b"MNLW".contains(&self.at(i + 1))) || self.at(i + 1) == b'Z' {
            self.emit(b"S", Some(b"X")); return i + if self.at(i + 1) == b'Z' { 2 } else { 1 };
        }
        if self.has(i, b"SC") {
            if self.at(i + 2) == b'H' {
                if self.has(i + 3, b"OO") || self.has(i + 3, b"ER") || self.has(i + 3, b"EN") ||
                    self.has(i + 3, b"UY") || self.has(i + 3, b"ED") || self.has(i + 3, b"EM") {
                    if self.has(i + 3, b"ER") || self.has(i + 3, b"EN") { self.emit(b"X", Some(b"SK")); }
                    else { self.emit(b"SK", None); }
                } else if i == 0 && !self.vowel(3) && self.at(3) != b'W' { self.emit(b"X", Some(b"S")); }
                else { self.emit(b"X", None); }
                return i + 3;
            }
            if b"IEY".contains(&self.at(i + 2)) { self.emit(b"S", None); } else { self.emit(b"SK", None); }
            return i + 3;
        }
        if i == self.length as i32 - 1 && (self.has(i - 2, b"AI") || self.has(i - 2, b"OI")) { self.emit(b"", Some(b"S")); }
        else { self.emit(b"S", None); }
        i + if b"SZ".contains(&self.at(i + 1)) { 2 } else { 1 }
    }

    fn t_rule(&mut self, i: i32) -> i32 {
        if self.has(i, b"TION") { self.emit(b"X", None); return i + 3; }
        if self.has(i, b"TIA") || self.has(i, b"TCH") { self.emit(b"X", None); return i + 3; }
        if self.has(i, b"TH") || self.has(i, b"TTH") {
            if self.has(i + 2, b"OM") || self.has(i + 2, b"AM") || self.has(0, b"VAN ") || self.has(0, b"VON ") || self.has(0, b"SCH") { self.emit(b"T", None); }
            else { self.emit(b"0", Some(b"T")); }
            return i + 2;
        }
        self.emit(b"T", None);
        i + if b"TD".contains(&self.at(i + 1)) { 2 } else { 1 }
    }

    fn w_rule(&mut self, i: i32) -> i32 {
        if self.has(i, b"WR") { self.emit(b"R", None); return i + 2; }
        if i == 0 && (self.vowel(i + 1) || self.has(i, b"WH")) {
            if self.vowel(i + 1) { self.emit(b"A", Some(b"F")); } else { self.emit(b"A", None); }
        }
        if (i == self.length as i32 - 1 && self.vowel(i - 1)) || self.has(i - 1, b"EWSKI") ||
            self.has(i - 1, b"EWSKY") || self.has(i - 1, b"OWSKI") || self.has(i - 1, b"OWSKY") || self.has(0, b"SCH") {
            self.emit(b"", Some(b"F")); return i + 1;
        }
        if self.has(i, b"WICZ") || self.has(i, b"WITZ") { self.emit(b"TS", Some(b"FX")); return i + 4; }
        i + 1
    }
}

fn uppercase(value: i64) -> u8 {
    if (b'a' as i64..=b'z' as i64).contains(&value) { (value - (b'a' - b'A') as i64) as u8 }
    else if value == 0xE7 { 0xC7 }
    else if value == 0xF1 { 0xD1 }
    else { value as u8 }
}

fn accepted(value: i64) -> bool {
    (b'A' as i64..=b'Z' as i64).contains(&value) || (b'a' as i64..=b'z' as i64).contains(&value) ||
        value == b' ' as i64 || value == 0xC7 || value == 0xE7 || value == 0xD1 || value == 0xF1
}

#[no_mangle]
pub unsafe extern "C" fn double_metaphone(
    values: *const i64,
    length: usize,
    output: *mut u8,
    output_capacity: usize,
) -> i64 {
    if values.is_null() || !(1..=34).contains(&length) { return -1; }
    let input = std::slice::from_raw_parts(values, length);
    if !(0..=TEXT_LIMIT as i64).contains(&input[0]) { return -1; }
    let text_length = input[0] as usize;
    if length != text_length + 1 || input[1..].iter().any(|&byte| !accepted(byte)) { return -1; }

    let mut scan = Encoder {
        text: [b' '; TEXT_LIMIT + PAD], length: text_length as u8,
        primary: [0; KEY_LIMIT], secondary: [0; KEY_LIMIT],
        primary_len: 0, secondary_len: 0, alternate_seen: false,
    };
    for (i, &byte) in input[1..].iter().enumerate() { scan.text[i] = uppercase(byte); }
    let slavo = scan.slavo_germanic();
    let mut index = 0i32;
    if scan.has(0, b"GN") || scan.has(0, b"KN") || scan.has(0, b"PN") || scan.has(0, b"WR") || scan.has(0, b"PS") { index = 1; }
    if scan.at(0) == b'X' { scan.emit(b"S", None); index = 1; }

    while index < scan.length as i32 &&
        (scan.primary_len < KEY_LIMIT as u8 || scan.secondary_len < KEY_LIMIT as u8) {
        match scan.at(index) {
            b'A' | b'E' | b'I' | b'O' | b'U' | b'Y' => { if index == 0 { scan.emit(b"A", None); } index += 1; }
            b'B' => { scan.emit(b"P", None); index += if scan.at(index + 1) == b'B' { 2 } else { 1 }; }
            0xC7 => { scan.emit(b"S", None); index += 1; }
            b'C' => index = scan.c_rule(index),
            b'D' => {
                if scan.has(index, b"DG") {
                    if b"IEY".contains(&scan.at(index + 2)) { scan.emit(b"J", None); index += 3; }
                    else { scan.emit(b"TK", None); index += 2; }
                } else if scan.has(index, b"DT") || scan.has(index, b"DD") { scan.emit(b"T", None); index += 2; }
                else { scan.emit(b"T", None); index += 1; }
            }
            b'F' => { scan.emit(b"F", None); index += if scan.at(index + 1) == b'F' { 2 } else { 1 }; }
            b'G' => index = scan.g_rule(index, slavo),
            b'H' => {
                if (index == 0 || scan.vowel(index - 1)) && scan.vowel(index + 1) { scan.emit(b"H", None); index += 2; }
                else { index += 1; }
            }
            b'J' => index = scan.j_rule(index, slavo),
            b'K' => { scan.emit(b"K", None); index += if scan.at(index + 1) == b'K' { 2 } else { 1 }; }
            b'L' => index = scan.l_rule(index),
            b'M' => {
                if (scan.has(index - 1, b"UMB") && (index + 1 == scan.length as i32 - 1 || scan.has(index + 2, b"ER"))) || scan.at(index + 1) == b'M' { index += 2; }
                else { index += 1; }
                scan.emit(b"M", None);
            }
            b'N' => { scan.emit(b"N", None); index += if scan.at(index + 1) == b'N' { 2 } else { 1 }; }
            0xD1 => { scan.emit(b"N", None); index += 1; }
            b'P' => {
                if scan.at(index + 1) == b'H' { scan.emit(b"F", None); index += 2; }
                else { scan.emit(b"P", None); index += if scan.at(index + 1) == b'P' || scan.at(index + 1) == b'B' { 2 } else { 1 }; }
            }
            b'Q' => { scan.emit(b"K", None); index += if scan.at(index + 1) == b'Q' { 2 } else { 1 }; }
            b'R' => {
                if index == scan.length as i32 - 1 && !slavo && scan.has(index - 2, b"IE") && !scan.has(index - 4, b"ME") && !scan.has(index - 4, b"MA") { scan.emit(b"", Some(b"R")); }
                else { scan.emit(b"R", None); }
                index += if scan.at(index + 1) == b'R' { 2 } else { 1 };
            }
            b'S' => index = scan.s_rule(index, slavo),
            b'T' => {
                if scan.has(index, b"TION") { scan.emit(b"X", None); index += 3; }
                else if scan.has(index, b"TIA") || scan.has(index, b"TCH") { scan.emit(b"X", None); index += 3; }
                else if scan.has(index, b"TH") || scan.has(index, b"TTH") {
                    if scan.has(index + 2, b"OM") || scan.has(index + 2, b"AM") || scan.has(0, b"VAN ") || scan.has(0, b"VON ") || scan.has(0, b"SCH") { scan.emit(b"T", None); }
                    else { scan.emit(b"0", Some(b"T")); }
                    index += 2;
                } else { scan.emit(b"T", None); index += if b"TD".contains(&scan.at(index + 1)) { 2 } else { 1 }; }
            }
            b'V' => { scan.emit(b"F", None); index += if scan.at(index + 1) == b'V' { 2 } else { 1 }; }
            b'W' => index = scan.w_rule(index),
            b'X' => {
                let french = index == scan.length as i32 - 1 &&
                    (scan.has(index - 3, b"IAU") || scan.has(index - 3, b"EAU") || scan.has(index - 2, b"AU") || scan.has(index - 2, b"OU"));
                if !french { scan.emit(b"KS", None); }
                index += if scan.at(index + 1) == b'C' || scan.at(index + 1) == b'X' { 2 } else { 1 };
            }
            b'Z' => {
                if scan.at(index + 1) == b'H' { scan.emit(b"J", None); index += 2; }
                else {
                    if scan.has(index + 1, b"ZO") || scan.has(index + 1, b"ZI") || scan.has(index + 1, b"ZA") ||
                        (slavo && index > 0 && scan.at(index - 1) != b'T') { scan.emit(b"S", Some(b"TS")); }
                    else { scan.emit(b"S", None); }
                    index += if scan.at(index + 1) == b'Z' { 2 } else { 1 };
                }
            }
            _ => index += 1,
        }
    }

    let mut second_len = if scan.alternate_seen { scan.secondary_len } else { 0 };
    if second_len == scan.primary_len && scan.primary[..scan.primary_len as usize] == scan.secondary[..scan.secondary_len as usize] { second_len = 0; }
    let required = 2 + scan.primary_len as usize + second_len as usize;
    if output.is_null() || output_capacity < required { return -2; }
    let result = std::slice::from_raw_parts_mut(output, required);
    result[0] = scan.primary_len;
    result[1] = second_len;
    let p = scan.primary_len as usize;
    let s = second_len as usize;
    result[2..2 + p].copy_from_slice(&scan.primary[..p]);
    result[2 + p..2 + p + s].copy_from_slice(&scan.secondary[..s]);
    required as i64
}
