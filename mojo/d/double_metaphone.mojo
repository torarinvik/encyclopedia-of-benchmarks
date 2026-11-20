from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime DM_TEXT_LIMIT = 32
comptime DM_KEY_LIMIT = 4

struct DmState:
    var text: InlineArray[UInt8, 37]
    var primary: InlineArray[UInt8, 4]
    var secondary: InlineArray[UInt8, 4]
    var length: Int
    var primary_len: Int
    var secondary_len: Int
    var alternate_seen: Bool

    fn __init__(out self):
        self.text = InlineArray[UInt8, 37](fill=UInt8(0))
        self.primary = InlineArray[UInt8, 4](fill=UInt8(0))
        self.secondary = InlineArray[UInt8, 4](fill=UInt8(0))
        self.length = 0
        self.primary_len = 0
        self.secondary_len = 0
        self.alternate_seen = False


fn dm_at(s: DmState, i: Int) -> UInt8:
    if i < 0 or i >= 37:
        return UInt8(32)
    return s.text[i]


fn dm_has(s: DmState, i: Int, pattern: String) -> Bool:
    let bytes = pattern.as_bytes()
    if i < 0 or i + len(bytes) > 37:
        return False
    for j in range(len(bytes)):
        if s.text[i + j] != bytes[j]:
            return False
    return True


fn dm_vowel(s: DmState, i: Int) -> Bool:
    if i < 0 or i >= s.length:
        return False
    let c = dm_at(s, i)
    return c == 65 or c == 69 or c == 73 or c == 79 or c == 85 or c == 89


fn dm_append(inout target: InlineArray[UInt8, 4], inout size: Int, fragment: String):
    for byte in fragment.as_bytes():
        if size >= DM_KEY_LIMIT:
            break
        target[size] = byte
        size += 1


fn dm_same(inout s: DmState, fragment: String):
    dm_append(s.primary, s.primary_len, fragment)
    dm_append(s.secondary, s.secondary_len, fragment)


fn dm_choice(inout s: DmState, main: String, alternate: String):
    dm_append(s.primary, s.primary_len, main)
    let alt = alternate.as_bytes()
    if len(alt) > 0:
        s.alternate_seen = True
        if alt[0] != UInt8(32):
            dm_append(s.secondary, s.secondary_len, alternate)
    elif len(main.as_bytes()) > 0 and main.as_bytes()[0] != UInt8(32):
        dm_append(s.secondary, s.secondary_len, main)


fn dm_slavo(s: DmState) -> Bool:
    for i in range(s.length):
        if dm_at(s, i) == 87 or dm_at(s, i) == 75 or dm_has(s, i, "CZ") or dm_has(s, i, "WITZ"):
            return True
    return False


fn dm_c(inout s: DmState, i: Int) -> Int:
    if i > 1 and not dm_vowel(s, i - 2) and dm_has(s, i - 1, "ACH") and dm_at(s, i + 2) != 73 and (dm_at(s, i + 2) != 69 or dm_has(s, i - 2, "BACHER") or dm_has(s, i - 2, "MACHER")):
        dm_same(s, "K"); return i + 2
    if i == 0 and dm_has(s, i, "CAESAR"):
        dm_same(s, "S"); return i + 2
    if dm_has(s, i, "CHIA"):
        dm_same(s, "K"); return i + 2
    if dm_has(s, i, "CH"):
        if i > 0 and dm_has(s, i, "CHAE"):
            dm_choice(s, "K", "X"); return i + 2
        if i == 0 and (dm_has(s, i + 1, "HARAC") or dm_has(s, i + 1, "HARIS") or dm_has(s, i + 1, "HOR") or dm_has(s, i + 1, "HYM") or dm_has(s, i + 1, "HIA") or dm_has(s, i + 1, "HEM")) and not dm_has(s, 0, "CHORE"):
            dm_same(s, "K"); return i + 2
        let hard = dm_has(s, 0, "VAN ") or dm_has(s, 0, "VON ") or dm_has(s, 0, "SCH") or dm_has(s, i - 2, "ORCHES") or dm_has(s, i - 2, "ARCHIT") or dm_has(s, i - 2, "ORCHID") or dm_at(s, i + 2) == 84 or dm_at(s, i + 2) == 83 or ((dm_at(s, i - 1) == 65 or dm_at(s, i - 1) == 79 or dm_at(s, i - 1) == 85 or dm_at(s, i - 1) == 69 or i == 0) and (dm_at(s, i + 2) == 76 or dm_at(s, i + 2) == 82 or dm_at(s, i + 2) == 78 or dm_at(s, i + 2) == 77 or dm_at(s, i + 2) == 66 or dm_at(s, i + 2) == 72 or dm_at(s, i + 2) == 70 or dm_at(s, i + 2) == 86 or dm_at(s, i + 2) == 87 or dm_at(s, i + 2) == 32))
        if hard:
            dm_same(s, "K")
        elif i > 0:
            if dm_has(s, 0, "MC"):
                dm_same(s, "K")
            else:
                dm_choice(s, "X", "K")
        else:
            dm_same(s, "X")
        return i + 2
    if dm_has(s, i, "CZ") and not dm_has(s, i - 2, "WICZ"):
        dm_choice(s, "S", "X"); return i + 2
    if dm_has(s, i + 1, "CIA"):
        dm_same(s, "X"); return i + 3
    if dm_has(s, i, "CC") and not (i == 1 and dm_at(s, 0) == 77):
        if (dm_at(s, i + 2) == 73 or dm_at(s, i + 2) == 69 or dm_at(s, i + 2) == 72) and not dm_has(s, i + 2, "HU"):
            if (i == 1 and dm_at(s, i - 1) == 65) or dm_has(s, i - 1, "UCCEE") or dm_has(s, i - 1, "UCCES"):
                dm_same(s, "KS")
            else:
                dm_same(s, "X")
            return i + 3
        dm_same(s, "K"); return i + 2
    if dm_has(s, i, "CK") or dm_has(s, i, "CG") or dm_has(s, i, "CQ"):
        dm_same(s, "K"); return i + 2
    if dm_has(s, i, "CI") or dm_has(s, i, "CE") or dm_has(s, i, "CY"):
        if dm_has(s, i, "CIO") or dm_has(s, i, "CIE") or dm_has(s, i, "CIA"):
            dm_choice(s, "S", "X")
        else:
            dm_same(s, "S")
        return i + 2
    dm_same(s, "K")
    if dm_has(s, i + 1, " C") or dm_has(s, i + 1, " Q") or dm_has(s, i + 1, " G"):
        return i + 3
    if (dm_at(s, i + 1) == 67 or dm_at(s, i + 1) == 75 or dm_at(s, i + 1) == 81) and not dm_has(s, i + 1, "CE") and not dm_has(s, i + 1, "CI"):
        return i + 2
    return i + 1


fn dm_g(inout s: DmState, i: Int, slavo: Bool) -> Int:
    if dm_at(s, i + 1) == 72:
        if i > 0 and not dm_vowel(s, i - 1):
            dm_same(s, "K"); return i + 2
        if i == 0:
            if dm_at(s, i + 2) == 73:
                dm_same(s, "J")
            else:
                dm_same(s, "K")
            return i + 2
        if (i > 1 and (dm_at(s, i - 2) == 66 or dm_at(s, i - 2) == 72 or dm_at(s, i - 2) == 68)) or (i > 2 and (dm_at(s, i - 3) == 66 or dm_at(s, i - 3) == 72 or dm_at(s, i - 3) == 68)) or (i > 3 and (dm_at(s, i - 4) == 66 or dm_at(s, i - 4) == 72)):
            return i + 2
        if i > 2 and dm_at(s, i - 1) == 85 and (dm_at(s, i - 3) == 67 or dm_at(s, i - 3) == 71 or dm_at(s, i - 3) == 76 or dm_at(s, i - 3) == 82 or dm_at(s, i - 3) == 84):
            dm_same(s, "F")
        elif i > 0 and dm_at(s, i - 1) != 73:
            dm_same(s, "K")
        return i + 2
    if dm_at(s, i + 1) == 78:
        if i == 1 and dm_vowel(s, 0) and not slavo:
            dm_choice(s, "KN", "N")
        elif not dm_has(s, i + 2, "EY") and dm_at(s, i + 1) != 89 and not slavo:
            dm_choice(s, "N", "KN")
        else:
            dm_same(s, "KN")
        return i + 2
    if dm_has(s, i + 1, "LI") and not slavo:
        dm_choice(s, "KL", "L"); return i + 2
    if i == 0 and (dm_at(s, i + 1) == 89 or dm_has(s, i + 1, "ES") or dm_has(s, i + 1, "EP") or dm_has(s, i + 1, "EB") or dm_has(s, i + 1, "EL") or dm_has(s, i + 1, "EY") or dm_has(s, i + 1, "IB") or dm_has(s, i + 1, "IL") or dm_has(s, i + 1, "IN") or dm_has(s, i + 1, "IE") or dm_has(s, i + 1, "EI") or dm_has(s, i + 1, "ER")):
        dm_choice(s, "K", "J"); return i + 2
    if (dm_has(s, i + 1, "ER") or dm_at(s, i + 1) == 89) and not dm_has(s, 0, "DANGER") and not dm_has(s, 0, "RANGER") and not dm_has(s, 0, "MANGER") and dm_at(s, i - 1) != 69 and dm_at(s, i - 1) != 73 and not dm_has(s, i - 1, "RGY") and not dm_has(s, i - 1, "OGY"):
        dm_choice(s, "K", "J"); return i + 2
    if dm_at(s, i + 1) == 69 or dm_at(s, i + 1) == 73 or dm_at(s, i + 1) == 89 or dm_has(s, i - 1, "AGGI") or dm_has(s, i - 1, "OGGI"):
        if dm_has(s, 0, "VAN ") or dm_has(s, 0, "VON ") or dm_has(s, 0, "SCH") or dm_has(s, i + 1, "ET"):
            dm_same(s, "K")
        elif dm_has(s, i + 1, "IER "):
            dm_same(s, "J")
        else:
            dm_choice(s, "J", "K")
        return i + 2
    dm_same(s, "K")
    return i + (2 if dm_at(s, i + 1) == 71 else 1)


fn dm_j(inout s: DmState, i: Int, slavo: Bool) -> Int:
    if dm_has(s, i, "JOSE") or dm_has(s, 0, "SAN "):
        if (i == 0 and dm_at(s, i + 4) == 32) or dm_has(s, 0, "SAN "):
            dm_same(s, "H")
        else:
            dm_choice(s, "J", "H")
        return i + 1
    if i == 0:
        dm_choice(s, "J", "A")
    elif dm_vowel(s, i - 1) and not slavo and (dm_at(s, i + 1) == 65 or dm_at(s, i + 1) == 79):
        dm_choice(s, "J", "H")
    elif i == s.length - 1:
        dm_choice(s, "J", " ")
    elif not (dm_at(s, i + 1) == 76 or dm_at(s, i + 1) == 84 or dm_at(s, i + 1) == 75 or dm_at(s, i + 1) == 83 or dm_at(s, i + 1) == 78 or dm_at(s, i + 1) == 77 or dm_at(s, i + 1) == 66 or dm_at(s, i + 1) == 90) and dm_at(s, i - 1) != 83 and dm_at(s, i - 1) != 75 and dm_at(s, i - 1) != 76:
        dm_same(s, "J")
    return i + (2 if dm_at(s, i + 1) == 74 else 1)


fn dm_l(inout s: DmState, i: Int) -> Int:
    if dm_at(s, i + 1) != 76:
        dm_same(s, "L"); return i + 1
    let n = s.length
    let spanish = (i == n - 3 and (dm_has(s, i - 1, "ILLO") or dm_has(s, i - 1, "ILLA") or dm_has(s, i - 1, "ALLE"))) or ((dm_has(s, n - 3, "AS") or dm_has(s, n - 3, "OS") or dm_at(s, n - 1) == 65 or dm_at(s, n - 1) == 79) and dm_has(s, i - 1, "ALLE"))
    if spanish:
        dm_choice(s, "L", " ")
    else:
        dm_same(s, "L")
    return i + 2


fn dm_s(inout s: DmState, i: Int, slavo: Bool) -> Int:
    if dm_has(s, i - 1, "ISL") or dm_has(s, i - 1, "YSL"):
        return i + 1
    if i == 0 and dm_has(s, i, "SUGAR"):
        dm_choice(s, "X", "S"); return i + 1
    if dm_has(s, i, "SH"):
        if dm_has(s, i + 1, "HEIM") or dm_has(s, i + 1, "HOEK") or dm_has(s, i + 1, "HOLM") or dm_has(s, i + 1, "HOLZ"):
            dm_same(s, "S")
        else:
            dm_same(s, "X")
        return i + 2
    if dm_has(s, i, "SIO") or dm_has(s, i, "SIA") or dm_has(s, i, "SIAN"):
        if not slavo:
            dm_choice(s, "S", "X")
        else:
            dm_same(s, "S")
        return i + 3
    if (i == 0 and (dm_at(s, i + 1) == 77 or dm_at(s, i + 1) == 78 or dm_at(s, i + 1) == 76 or dm_at(s, i + 1) == 87)) or dm_at(s, i + 1) == 90:
        dm_choice(s, "S", "X")
        return i + (2 if dm_at(s, i + 1) == 90 else 1)
    if dm_has(s, i, "SC"):
        if dm_at(s, i + 2) == 72:
            if dm_has(s, i + 3, "OO") or dm_has(s, i + 3, "ER") or dm_has(s, i + 3, "EN") or dm_has(s, i + 3, "UY") or dm_has(s, i + 3, "ED") or dm_has(s, i + 3, "EM"):
                if dm_has(s, i + 3, "ER") or dm_has(s, i + 3, "EN"):
                    dm_choice(s, "X", "SK")
                else:
                    dm_same(s, "SK")
            elif i == 0 and not dm_vowel(s, 3) and dm_at(s, 3) != 87:
                dm_choice(s, "X", "S")
            else:
                dm_same(s, "X")
            return i + 3
        if dm_at(s, i + 2) == 73 or dm_at(s, i + 2) == 69 or dm_at(s, i + 2) == 89:
            dm_same(s, "S")
        else:
            dm_same(s, "SK")
        return i + 3
    if i == s.length - 1 and (dm_has(s, i - 2, "AI") or dm_has(s, i - 2, "OI")):
        dm_choice(s, "", "S")
    else:
        dm_same(s, "S")
    return i + (2 if dm_at(s, i + 1) == 83 or dm_at(s, i + 1) == 90 else 1)


fn dm_t(inout s: DmState, i: Int) -> Int:
    if dm_has(s, i, "TION"):
        dm_same(s, "X"); return i + 3
    if dm_has(s, i, "TIA") or dm_has(s, i, "TCH"):
        dm_same(s, "X"); return i + 3
    if dm_has(s, i, "TH") or dm_has(s, i, "TTH"):
        if dm_has(s, i + 2, "OM") or dm_has(s, i + 2, "AM") or dm_has(s, 0, "VAN ") or dm_has(s, 0, "VON ") or dm_has(s, 0, "SCH"):
            dm_same(s, "T")
        else:
            dm_choice(s, "0", "T")
        return i + 2
    dm_same(s, "T")
    return i + (2 if dm_at(s, i + 1) == 84 or dm_at(s, i + 1) == 68 else 1)


fn dm_w(inout s: DmState, i: Int) -> Int:
    if dm_has(s, i, "WR"):
        dm_same(s, "R"); return i + 2
    if i == 0 and (dm_vowel(s, i + 1) or dm_has(s, i, "WH")):
        if dm_vowel(s, i + 1):
            dm_choice(s, "A", "F")
        else:
            dm_same(s, "A")
    if (i == s.length - 1 and dm_vowel(s, i - 1)) or dm_has(s, i - 1, "EWSKI") or dm_has(s, i - 1, "EWSKY") or dm_has(s, i - 1, "OWSKI") or dm_has(s, i - 1, "OWSKY") or dm_has(s, 0, "SCH"):
        dm_choice(s, "", "F"); return i + 1
    if dm_has(s, i, "WICZ") or dm_has(s, i, "WITZ"):
        dm_choice(s, "TS", "FX"); return i + 4
    return i + 1


fn dm_upper(value: Int64) -> UInt8:
    if value >= 97 and value <= 122:
        return UInt8(value - 32)
    if value == 0xE7:
        return UInt8(0xC7)
    if value == 0xF1:
        return UInt8(0xD1)
    return UInt8(value)


@export("double_metaphone")
fn double_metaphone(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], output_capacity: c_size_t,
) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 1 or length > 34:
        return -1
    if values[0] < 0 or values[0] > DM_TEXT_LIMIT:
        return -1
    let count = Int(values[0])
    if length != c_size_t(count + 1):
        return -1
    var s = DmState()
    for j in range(37):
        s.text[j] = UInt8(32)
    s.length = count
    for j in range(count):
        let raw = values[j + 1]
        if not ((raw >= 65 and raw <= 90) or (raw >= 97 and raw <= 122) or raw == 32 or raw == 0xC7 or raw == 0xE7 or raw == 0xD1 or raw == 0xF1):
            return -1
        s.text[j] = dm_upper(raw)
    let slavo = dm_slavo(s)
    var i = 0
    if dm_has(s, 0, "GN") or dm_has(s, 0, "KN") or dm_has(s, 0, "PN") or dm_has(s, 0, "WR") or dm_has(s, 0, "PS"):
        i = 1
    if dm_at(s, 0) == 88:
        dm_same(s, "S"); i = 1
    while i < s.length and (s.primary_len < DM_KEY_LIMIT or s.secondary_len < DM_KEY_LIMIT):
        let c = dm_at(s, i)
        if c == 65 or c == 69 or c == 73 or c == 79 or c == 85 or c == 89:
            if i == 0: dm_same(s, "A")
            i += 1
        elif c == 66:
            dm_same(s, "P"); i += 2 if dm_at(s, i + 1) == 66 else 1
        elif c == 0xC7:
            dm_same(s, "S"); i += 1
        elif c == 67:
            i = dm_c(s, i)
        elif c == 68:
            if dm_has(s, i, "DG"):
                if dm_at(s, i + 2) == 73 or dm_at(s, i + 2) == 69 or dm_at(s, i + 2) == 89:
                    dm_same(s, "J"); i += 3
                else:
                    dm_same(s, "TK"); i += 2
            elif dm_has(s, i, "DT") or dm_has(s, i, "DD"):
                dm_same(s, "T"); i += 2
            else:
                dm_same(s, "T"); i += 1
        elif c == 70:
            dm_same(s, "F"); i += 2 if dm_at(s, i + 1) == 70 else 1
        elif c == 71:
            i = dm_g(s, i, slavo)
        elif c == 72:
            if (i == 0 or dm_vowel(s, i - 1)) and dm_vowel(s, i + 1):
                dm_same(s, "H"); i += 2
            else:
                i += 1
        elif c == 74:
            i = dm_j(s, i, slavo)
        elif c == 75:
            dm_same(s, "K"); i += 2 if dm_at(s, i + 1) == 75 else 1
        elif c == 76:
            i = dm_l(s, i)
        elif c == 77:
            if (dm_has(s, i - 1, "UMB") and (i + 1 == s.length - 1 or dm_has(s, i + 2, "ER"))) or dm_at(s, i + 1) == 77:
                i += 2
            else:
                i += 1
            dm_same(s, "M")
        elif c == 78:
            dm_same(s, "N"); i += 2 if dm_at(s, i + 1) == 78 else 1
        elif c == 0xD1:
            dm_same(s, "N"); i += 1
        elif c == 80:
            if dm_at(s, i + 1) == 72:
                dm_same(s, "F"); i += 2
            else:
                dm_same(s, "P"); i += 2 if dm_at(s, i + 1) == 80 or dm_at(s, i + 1) == 66 else 1
        elif c == 81:
            dm_same(s, "K"); i += 2 if dm_at(s, i + 1) == 81 else 1
        elif c == 82:
            if i == s.length - 1 and not slavo and dm_has(s, i - 2, "IE") and not dm_has(s, i - 4, "ME") and not dm_has(s, i - 4, "MA"):
                dm_choice(s, "", "R")
            else:
                dm_same(s, "R")
            i += 2 if dm_at(s, i + 1) == 82 else 1
        elif c == 83:
            i = dm_s(s, i, slavo)
        elif c == 84:
            i = dm_t(s, i)
        elif c == 86:
            dm_same(s, "F"); i += 2 if dm_at(s, i + 1) == 86 else 1
        elif c == 87:
            i = dm_w(s, i)
        elif c == 88:
            let french = i == s.length - 1 and (dm_has(s, i - 3, "IAU") or dm_has(s, i - 3, "EAU") or dm_has(s, i - 2, "AU") or dm_has(s, i - 2, "OU"))
            if not french: dm_same(s, "KS")
            i += 2 if dm_at(s, i + 1) == 67 or dm_at(s, i + 1) == 88 else 1
        elif c == 90:
            if dm_at(s, i + 1) == 72:
                dm_same(s, "J"); i += 2
            else:
                if dm_has(s, i + 1, "ZO") or dm_has(s, i + 1, "ZI") or dm_has(s, i + 1, "ZA") or (slavo and i > 0 and dm_at(s, i - 1) != 84):
                    dm_choice(s, "S", "TS")
                else:
                    dm_same(s, "S")
                i += 2 if dm_at(s, i + 1) == 90 else 1
        else:
            i += 1
    var second_len = s.secondary_len if s.alternate_seen else 0
    if second_len == s.primary_len and second_len == s.secondary_len:
        var equal = True
        for j in range(s.primary_len):
            if s.primary[j] != s.secondary[j]: equal = False
        if equal: second_len = 0
    let required = 2 + s.primary_len + second_len
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or output_capacity < c_size_t(required):
        return -2
    output[0] = UInt8(s.primary_len)
    output[1] = UInt8(second_len)
    for j in range(s.primary_len): output[j + 2] = s.primary[j]
    for j in range(second_len): output[j + 2 + s.primary_len] = s.secondary[j]
    return Int64(required)
