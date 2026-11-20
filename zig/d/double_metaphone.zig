const std = @import("std");

const TextLimit: usize = 32;
const Pad: usize = 5;
const KeyLimit: usize = 4;

const Encoder = struct {
    text: [TextLimit + Pad]u8,
    primary: [KeyLimit]u8,
    secondary: [KeyLimit]u8,
    length: i32,
    primary_len: u8,
    secondary_len: u8,
    alternate_seen: bool,

    fn at(self: *const Encoder, index: i32) u8 {
        if (index >= 0 and index < @as(i32, @intCast(self.text.len))) return self.text[@intCast(index)];
        return ' ';
    }

    fn has(self: *const Encoder, index: i32, pattern: []const u8) bool {
        if (index < 0) return false;
        const start: usize = @intCast(index);
        if (start + pattern.len > self.text.len) return false;
        return std.mem.eql(u8, self.text[start .. start + pattern.len], pattern);
    }

    fn vowel(self: *const Encoder, index: i32) bool {
        if (index < 0 or index >= self.length) return false;
        return std.mem.indexOfScalar(u8, "AEIOUY", self.at(index)) != null;
    }

    fn slavo(self: *const Encoder) bool {
        var index: i32 = 0;
        while (index < self.length) : (index += 1) {
            if (self.at(index) == 'W' or self.at(index) == 'K' or self.has(index, "CZ") or self.has(index, "WITZ"))
                return true;
        }
        return false;
    }

    fn append(target: *[KeyLimit]u8, size: *u8, fragment: []const u8) void {
        for (fragment) |byte| {
            if (size.* >= KeyLimit) break;
            target[size.*] = byte;
            size.* += 1;
        }
    }

    fn emit(self: *Encoder, main: []const u8, alternate: ?[]const u8) void {
        append(&self.primary, &self.primary_len, main);
        if (alternate) |other| {
            if (other.len > 0) {
                self.alternate_seen = true;
                if (other[0] != ' ') append(&self.secondary, &self.secondary_len, other);
            } else if (main.len > 0 and main[0] != ' ') {
                append(&self.secondary, &self.secondary_len, main);
            }
        } else {
            append(&self.secondary, &self.secondary_len, main);
        }
    }

    fn cRule(self: *Encoder, i: i32) i32 {
        if (i > 1 and !self.vowel(i - 2) and self.has(i - 1, "ACH") and self.at(i + 2) != 'I' and
            (self.at(i + 2) != 'E' or self.has(i - 2, "BACHER") or self.has(i - 2, "MACHER"))) {
            self.emit("K", null); return i + 2;
        }
        if (i == 0 and self.has(i, "CAESAR")) { self.emit("S", null); return i + 2; }
        if (self.has(i, "CHIA")) { self.emit("K", null); return i + 2; }
        if (self.has(i, "CH")) {
            if (i > 0 and self.has(i, "CHAE")) { self.emit("K", "X"); return i + 2; }
            if (i == 0 and (self.has(i + 1, "HARAC") or self.has(i + 1, "HARIS") or self.has(i + 1, "HOR") or
                self.has(i + 1, "HYM") or self.has(i + 1, "HIA") or self.has(i + 1, "HEM")) and !self.has(0, "CHORE")) {
                self.emit("K", null); return i + 2;
            }
            const hard = self.has(0, "VAN ") or self.has(0, "VON ") or self.has(0, "SCH") or
                self.has(i - 2, "ORCHES") or self.has(i - 2, "ARCHIT") or self.has(i - 2, "ORCHID") or
                self.at(i + 2) == 'T' or self.at(i + 2) == 'S' or
                ((std.mem.indexOfScalar(u8, "AOUE", self.at(i - 1)) != null or i == 0) and
                 std.mem.indexOfScalar(u8, "LRNMBHFVW ", self.at(i + 2)) != null);
            if (hard) self.emit("K", null)
            else if (i > 0) {
                if (self.has(0, "MC")) self.emit("K", null) else self.emit("X", "K");
            } else self.emit("X", null);
            return i + 2;
        }
        if (self.has(i, "CZ") and !self.has(i - 2, "WICZ")) { self.emit("S", "X"); return i + 2; }
        if (self.has(i + 1, "CIA")) { self.emit("X", null); return i + 3; }
        if (self.has(i, "CC") and !(i == 1 and self.at(0) == 'M')) {
            if (std.mem.indexOfScalar(u8, "IEH", self.at(i + 2)) != null and !self.has(i + 2, "HU")) {
                if ((i == 1 and self.at(i - 1) == 'A') or self.has(i - 1, "UCCEE") or self.has(i - 1, "UCCES"))
                    self.emit("KS", null)
                else self.emit("X", null);
                return i + 3;
            }
            self.emit("K", null); return i + 2;
        }
        if (self.has(i, "CK") or self.has(i, "CG") or self.has(i, "CQ")) { self.emit("K", null); return i + 2; }
        if (self.has(i, "CI") or self.has(i, "CE") or self.has(i, "CY")) {
            if (self.has(i, "CIO") or self.has(i, "CIE") or self.has(i, "CIA")) self.emit("S", "X") else self.emit("S", null);
            return i + 2;
        }
        self.emit("K", null);
        if (self.has(i + 1, " C") or self.has(i + 1, " Q") or self.has(i + 1, " G")) return i + 3;
        if (std.mem.indexOfScalar(u8, "CKQ", self.at(i + 1)) != null and !self.has(i + 1, "CE") and !self.has(i + 1, "CI")) return i + 2;
        return i + 1;
    }

    fn gRule(self: *Encoder, i: i32, germanic: bool) i32 {
        if (self.at(i + 1) == 'H') {
            if (i > 0 and !self.vowel(i - 1)) { self.emit("K", null); return i + 2; }
            if (i == 0) { if (self.at(i + 2) == 'I') self.emit("J", null) else self.emit("K", null); return i + 2; }
            const silent = (i > 1 and std.mem.indexOfScalar(u8, "BHD", self.at(i - 2)) != null) or
                (i > 2 and std.mem.indexOfScalar(u8, "BHD", self.at(i - 3)) != null) or
                (i > 3 and std.mem.indexOfScalar(u8, "BH", self.at(i - 4)) != null);
            if (silent) return i + 2;
            if (i > 2 and self.at(i - 1) == 'U' and std.mem.indexOfScalar(u8, "CGLRT", self.at(i - 3)) != null)
                self.emit("F", null)
            else if (i > 0 and self.at(i - 1) != 'I') self.emit("K", null);
            return i + 2;
        }
        if (self.at(i + 1) == 'N') {
            if (i == 1 and self.vowel(0) and !germanic) self.emit("KN", "N")
            else if (!self.has(i + 2, "EY") and self.at(i + 1) != 'Y' and !germanic) self.emit("N", "KN")
            else self.emit("KN", null);
            return i + 2;
        }
        if (self.has(i + 1, "LI") and !germanic) { self.emit("KL", "L"); return i + 2; }
        if (i == 0 and (self.at(i + 1) == 'Y' or self.has(i + 1, "ES") or self.has(i + 1, "EP") or
            self.has(i + 1, "EB") or self.has(i + 1, "EL") or self.has(i + 1, "EY") or
            self.has(i + 1, "IB") or self.has(i + 1, "IL") or self.has(i + 1, "IN") or
            self.has(i + 1, "IE") or self.has(i + 1, "EI") or self.has(i + 1, "ER"))) {
            self.emit("K", "J"); return i + 2;
        }
        if ((self.has(i + 1, "ER") or self.at(i + 1) == 'Y') and !self.has(0, "DANGER") and !self.has(0, "RANGER") and
            !self.has(0, "MANGER") and self.at(i - 1) != 'E' and self.at(i - 1) != 'I' and
            !self.has(i - 1, "RGY") and !self.has(i - 1, "OGY")) { self.emit("K", "J"); return i + 2; }
        if (std.mem.indexOfScalar(u8, "EIY", self.at(i + 1)) != null or self.has(i - 1, "AGGI") or self.has(i - 1, "OGGI")) {
            if (self.has(0, "VAN ") or self.has(0, "VON ") or self.has(0, "SCH") or self.has(i + 1, "ET")) self.emit("K", null)
            else if (self.has(i + 1, "IER ")) self.emit("J", null)
            else self.emit("J", "K");
            return i + 2;
        }
        self.emit("K", null);
        return i + if (self.at(i + 1) == 'G') 2 else 1;
    }

    fn jRule(self: *Encoder, i: i32, germanic: bool) i32 {
        if (self.has(i, "JOSE") or self.has(0, "SAN ")) {
            if ((i == 0 and self.at(i + 4) == ' ') or self.has(0, "SAN ")) self.emit("H", null) else self.emit("J", "H");
            return i + 1;
        }
        if (i == 0) self.emit("J", "A")
        else if (self.vowel(i - 1) and !germanic and std.mem.indexOfScalar(u8, "AO", self.at(i + 1)) != null) self.emit("J", "H")
        else if (i == self.length - 1) self.emit("J", " ")
        else if (std.mem.indexOfScalar(u8, "LTKSNMBZ", self.at(i + 1)) == null and std.mem.indexOfScalar(u8, "SKL", self.at(i - 1)) == null) self.emit("J", null);
        return i + if (self.at(i + 1) == 'J') 2 else 1;
    }

    fn lRule(self: *Encoder, i: i32) i32 {
        if (self.at(i + 1) != 'L') { self.emit("L", null); return i + 1; }
        const n = self.length;
        const spanish = (i == n - 3 and (self.has(i - 1, "ILLO") or self.has(i - 1, "ILLA") or self.has(i - 1, "ALLE"))) or
            ((self.has(n - 3, "AS") or self.has(n - 3, "OS") or self.at(n - 1) == 'A' or self.at(n - 1) == 'O') and self.has(i - 1, "ALLE"));
        if (spanish) self.emit("L", " ") else self.emit("L", null);
        return i + 2;
    }

    fn sRule(self: *Encoder, i: i32, germanic: bool) i32 {
        if (self.has(i - 1, "ISL") or self.has(i - 1, "YSL")) return i + 1;
        if (i == 0 and self.has(i, "SUGAR")) { self.emit("X", "S"); return i + 1; }
        if (self.has(i, "SH")) {
            if (self.has(i + 1, "HEIM") or self.has(i + 1, "HOEK") or self.has(i + 1, "HOLM") or self.has(i + 1, "HOLZ")) self.emit("S", null)
            else self.emit("X", null);
            return i + 2;
        }
        if (self.has(i, "SIO") or self.has(i, "SIA") or self.has(i, "SIAN")) {
            if (!germanic) self.emit("S", "X") else self.emit("S", null);
            return i + 3;
        }
        if ((i == 0 and std.mem.indexOfScalar(u8, "MNLW", self.at(i + 1)) != null) or self.at(i + 1) == 'Z') {
            self.emit("S", "X"); return i + if (self.at(i + 1) == 'Z') 2 else 1;
        }
        if (self.has(i, "SC")) {
            if (self.at(i + 2) == 'H') {
                if (self.has(i + 3, "OO") or self.has(i + 3, "ER") or self.has(i + 3, "EN") or self.has(i + 3, "UY") or self.has(i + 3, "ED") or self.has(i + 3, "EM")) {
                    if (self.has(i + 3, "ER") or self.has(i + 3, "EN")) self.emit("X", "SK") else self.emit("SK", null);
                } else if (i == 0 and !self.vowel(3) and self.at(3) != 'W') self.emit("X", "S") else self.emit("X", null);
                return i + 3;
            }
            if (std.mem.indexOfScalar(u8, "IEY", self.at(i + 2)) != null) self.emit("S", null) else self.emit("SK", null);
            return i + 3;
        }
        const n = self.length;
        if (i == n - 1 and (self.has(i - 2, "AI") or self.has(i - 2, "OI"))) self.emit("", "S") else self.emit("S", null);
        return i + if (self.at(i + 1) == 'S' or self.at(i + 1) == 'Z') 2 else 1;
    }

    fn tRule(self: *Encoder, i: i32) i32 {
        if (self.has(i, "TION")) { self.emit("X", null); return i + 3; }
        if (self.has(i, "TIA") or self.has(i, "TCH")) { self.emit("X", null); return i + 3; }
        if (self.has(i, "TH") or self.has(i, "TTH")) {
            if (self.has(i + 2, "OM") or self.has(i + 2, "AM") or self.has(0, "VAN ") or self.has(0, "VON ") or self.has(0, "SCH")) self.emit("T", null)
            else self.emit("0", "T");
            return i + 2;
        }
        self.emit("T", null);
        return i + if (self.at(i + 1) == 'T' or self.at(i + 1) == 'D') 2 else 1;
    }

    fn wRule(self: *Encoder, i: i32) i32 {
        if (self.has(i, "WR")) { self.emit("R", null); return i + 2; }
        if (i == 0 and (self.vowel(i + 1) or self.has(i, "WH"))) {
            if (self.vowel(i + 1)) self.emit("A", "F") else self.emit("A", null);
        }
        if ((i == self.length - 1 and self.vowel(i - 1)) or self.has(i - 1, "EWSKI") or self.has(i - 1, "EWSKY") or
            self.has(i - 1, "OWSKI") or self.has(i - 1, "OWSKY") or self.has(0, "SCH")) {
            self.emit("", "F"); return i + 1;
        }
        if (self.has(i, "WICZ") or self.has(i, "WITZ")) { self.emit("TS", "FX"); return i + 4; }
        return i + 1;
    }
};

fn uppercase(value: i64) u8 {
    if (value >= 'a' and value <= 'z') return @intCast(value - ('a' - 'A'));
    if (value == 0xe7) return 0xc7;
    if (value == 0xf1) return 0xd1;
    return @intCast(value);
}

fn accepted(value: i64) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z') or value == ' ' or
        value == 0xc7 or value == 0xe7 or value == 0xd1 or value == 0xf1;
}

export fn double_metaphone(values_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (values_opt == null or length < 1 or length > 34) return -1;
    const values = values_opt.?;
    if (values[0] < 0 or values[0] > @as(i64, @intCast(TextLimit))) return -1;
    const count: usize = @intCast(values[0]);
    if (length != count + 1) return -1;
    var scan = Encoder{ .text = [_]u8{' '} ** (TextLimit + Pad), .primary = [_]u8{0} ** KeyLimit,
        .secondary = [_]u8{0} ** KeyLimit, .length = @intCast(count), .primary_len = 0, .secondary_len = 0, .alternate_seen = false };
    for (0..count) |i| {
        const byte = values[i + 1];
        if (!accepted(byte)) return -1;
        scan.text[i] = uppercase(byte);
    }
    const germanic = scan.slavo();
    var index: i32 = 0;
    if (scan.has(0, "GN") or scan.has(0, "KN") or scan.has(0, "PN") or scan.has(0, "WR") or scan.has(0, "PS")) index = 1;
    if (scan.at(0) == 'X') { scan.emit("S", null); index = 1; }
    while (index < scan.length and (scan.primary_len < @as(u8, KeyLimit) or scan.secondary_len < @as(u8, KeyLimit))) {
        switch (scan.at(index)) {
            'A', 'E', 'I', 'O', 'U', 'Y' => { if (index == 0) scan.emit("A", null); index += 1; },
            'B' => { scan.emit("P", null); index += if (scan.at(index + 1) == 'B') 2 else 1; },
            0xc7 => { scan.emit("S", null); index += 1; },
            'C' => index = scan.cRule(index),
            'D' => {
                if (scan.has(index, "DG")) {
                    if (std.mem.indexOfScalar(u8, "IEY", scan.at(index + 2)) != null) { scan.emit("J", null); index += 3; }
                    else { scan.emit("TK", null); index += 2; }
                } else if (scan.has(index, "DT") or scan.has(index, "DD")) { scan.emit("T", null); index += 2; }
                else { scan.emit("T", null); index += 1; }
            },
            'F' => { scan.emit("F", null); index += if (scan.at(index + 1) == 'F') 2 else 1; },
            'G' => index = scan.gRule(index, germanic),
            'H' => { if ((index == 0 or scan.vowel(index - 1)) and scan.vowel(index + 1)) { scan.emit("H", null); index += 2; } else index += 1; },
            'J' => index = scan.jRule(index, germanic),
            'K' => { scan.emit("K", null); index += if (scan.at(index + 1) == 'K') 2 else 1; },
            'L' => index = scan.lRule(index),
            'M' => { if ((scan.has(index - 1, "UMB") and (index + 1 == scan.length - 1 or scan.has(index + 2, "ER"))) or scan.at(index + 1) == 'M') index += 2 else index += 1; scan.emit("M", null); },
            'N' => { scan.emit("N", null); index += if (scan.at(index + 1) == 'N') 2 else 1; },
            0xd1 => { scan.emit("N", null); index += 1; },
            'P' => { if (scan.at(index + 1) == 'H') { scan.emit("F", null); index += 2; } else { scan.emit("P", null); index += if (scan.at(index + 1) == 'P' or scan.at(index + 1) == 'B') 2 else 1; } },
            'Q' => { scan.emit("K", null); index += if (scan.at(index + 1) == 'Q') 2 else 1; },
            'R' => { if (index == scan.length - 1 and !germanic and scan.has(index - 2, "IE") and !scan.has(index - 4, "ME") and !scan.has(index - 4, "MA")) scan.emit("", "R") else scan.emit("R", null); index += if (scan.at(index + 1) == 'R') 2 else 1; },
            'S' => index = scan.sRule(index, germanic),
            'T' => index = scan.tRule(index),
            'V' => { scan.emit("F", null); index += if (scan.at(index + 1) == 'V') 2 else 1; },
            'W' => index = scan.wRule(index),
            'X' => { const french = index == scan.length - 1 and (scan.has(index - 3, "IAU") or scan.has(index - 3, "EAU") or scan.has(index - 2, "AU") or scan.has(index - 2, "OU")); if (!french) scan.emit("KS", null); index += if (scan.at(index + 1) == 'C' or scan.at(index + 1) == 'X') 2 else 1; },
            'Z' => { if (scan.at(index + 1) == 'H') { scan.emit("J", null); index += 2; } else { if (scan.has(index + 1, "ZO") or scan.has(index + 1, "ZI") or scan.has(index + 1, "ZA") or (germanic and index > 0 and scan.at(index - 1) != 'T')) scan.emit("S", "TS") else scan.emit("S", null); index += if (scan.at(index + 1) == 'Z') 2 else 1; } },
            else => index += 1,
        }
    }
    const primary_len: usize = @intCast(scan.primary_len);
    var second_len: usize = if (scan.alternate_seen) @intCast(scan.secondary_len) else 0;
    if (second_len == primary_len and std.mem.eql(u8, scan.primary[0..primary_len], scan.secondary[0..second_len])) second_len = 0;
    const required: usize = 2 + primary_len + second_len;
    if (output_opt == null or output_capacity < required) return -2;
    const output = output_opt.?;
    output[0] = scan.primary_len; output[1] = @intCast(second_len);
    for (0..primary_len) |i| output[i + 2] = scan.primary[i];
    for (0..second_len) |i| output[i + 2 + primary_len] = scan.secondary[i];
    return @intCast(required);
}
