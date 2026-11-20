const MAX_TEXT: usize = 64;
const SCRATCH: usize = 128;
const CODE_BYTES: usize = 10;

fn replaceAll(text: []u8, length: *usize, old: []const u8, replacement: []const u8) void {
    var next: [SCRATCH]u8 = @splat(0);
    var out: usize = 0;
    var at: usize = 0;
    while (at < length.*) {
        var matched = old.len > 0 and at + old.len <= length.*;
        if (matched) {
            for (0..old.len) |j| { if (text[at + j] != old[j]) matched = false; }
        }
        if (matched) {
            for (replacement) |byte| { next[out] = byte; out += 1; }
            at += old.len;
        } else { next[out] = text[at]; out += 1; at += 1; }
    }
    for (0..out) |i| text[i] = next[i];
    length.* = out;
}

fn replacePrefix(text: []u8, length: *usize, old: []const u8, replacement: []const u8) void {
    if (length.* < old.len) return;
    for (0..old.len) |i| { if (text[i] != old[i]) return; }
    const tail = length.* - old.len;
    var i = tail;
    while (i > 0) { i -= 1; text[replacement.len + i] = text[old.len + i]; }
    for (0..replacement.len) |j| text[j] = replacement[j];
    length.* = replacement.len + tail;
}

fn replaceSuffix(text: []u8, length: *usize, old: []const u8, replacement: []const u8) void {
    if (length.* < old.len) return;
    const start = length.* - old.len;
    for (0..old.len) |i| { if (text[start + i] != old[i]) return; }
    for (0..replacement.len) |i| text[start + i] = replacement[i];
    length.* = start + replacement.len;
}

fn replaceChar(text: []u8, length: usize, old: u8, replacement: u8) void {
    for (0..length) |i| { if (text[i] == old) text[i] = replacement; }
}

fn squeeze(text: []u8, length: *usize, letter: u8, marker: u8) void {
    var out: usize = 0;
    for (0..length.*) |i| {
        if (text[i] == letter and out > 0 and text[out - 1] == marker) continue;
        text[out] = if (text[i] == letter) marker else text[i];
        out += 1;
    }
    length.* = out;
}

fn encode(input: [*c]const i64) [CODE_BYTES]u8 {
    var text: [SCRATCH]u8 = @splat(0);
    var n: usize = @intCast(input[0]);
    for (0..n) |i| {
        const code: u8 = @intCast(input[i + 1]);
        text[i] = if (code >= 'A' and code <= 'Z') code + 32 else code;
    }
    if (n == 0) {
        const empty: [CODE_BYTES]u8 = @splat('1');
        return empty;
    }
    if (text[n - 1] == 'e') n -= 1;
    replacePrefix(text[0..], &n, "cough", "cou2f");
    replacePrefix(text[0..], &n, "rough", "rou2f");
    replacePrefix(text[0..], &n, "tough", "tou2f");
    replacePrefix(text[0..], &n, "enough", "enou2f");
    replacePrefix(text[0..], &n, "trough", "trou2f");
    replacePrefix(text[0..], &n, "gn", "2n");
    replaceSuffix(text[0..], &n, "mb", "m2");
    replaceAll(text[0..], &n, "cq", "2q"); replaceAll(text[0..], &n, "ci", "si");
    replaceAll(text[0..], &n, "ce", "se"); replaceAll(text[0..], &n, "cy", "sy");
    replaceAll(text[0..], &n, "tch", "2ch");
    replaceChar(text[0..], n, 'c', 'k'); replaceChar(text[0..], n, 'q', 'k');
    replaceChar(text[0..], n, 'x', 'k'); replaceChar(text[0..], n, 'v', 'f');
    replaceAll(text[0..], &n, "dg", "2g"); replaceAll(text[0..], &n, "tio", "sio");
    replaceAll(text[0..], &n, "tia", "sia"); replaceChar(text[0..], n, 'd', 't');
    replaceAll(text[0..], &n, "ph", "fh"); replaceChar(text[0..], n, 'b', 'p');
    replaceAll(text[0..], &n, "sh", "s2"); replaceChar(text[0..], n, 'z', 's');
    if (n > 0 and (text[0] == 'a' or text[0] == 'e' or text[0] == 'i' or text[0] == 'o' or text[0] == 'u')) text[0] = 'A';
    for (0..n) |i| {
        if (text[i] == 'a' or text[i] == 'e' or text[i] == 'i' or text[i] == 'o' or text[i] == 'u') text[i] = '3';
    }
    replaceChar(text[0..], n, 'j', 'y');
    replacePrefix(text[0..], &n, "y3", "Y3"); replacePrefix(text[0..], &n, "y", "A");
    replaceChar(text[0..], n, 'y', '3');
    replaceAll(text[0..], &n, "3gh3", "3kh3"); replaceAll(text[0..], &n, "gh", "22");
    replaceChar(text[0..], n, 'g', 'k');
    squeeze(text[0..], &n, 's', 'S'); squeeze(text[0..], &n, 't', 'T'); squeeze(text[0..], &n, 'p', 'P');
    squeeze(text[0..], &n, 'k', 'K'); squeeze(text[0..], &n, 'f', 'F'); squeeze(text[0..], &n, 'm', 'M'); squeeze(text[0..], &n, 'n', 'N');
    replaceAll(text[0..], &n, "w3", "W3"); replaceAll(text[0..], &n, "wh3", "Wh3");
    replaceSuffix(text[0..], &n, "w", "3"); replaceChar(text[0..], n, 'w', '2');
    replacePrefix(text[0..], &n, "h", "A"); replaceChar(text[0..], n, 'h', '2');
    replaceAll(text[0..], &n, "r3", "R3"); replaceSuffix(text[0..], &n, "r", "3"); replaceChar(text[0..], n, 'r', '2');
    replaceAll(text[0..], &n, "l3", "L3"); replaceSuffix(text[0..], &n, "l", "3"); replaceChar(text[0..], n, 'l', '2');
    var out: usize = 0;
    for (0..n) |i| { if (text[i] != '2') { text[out] = text[i]; out += 1; } }
    n = out;
    replaceSuffix(text[0..], &n, "3", "A");
    out = 0;
    for (0..n) |i| { if (text[i] != '3') { text[out] = text[i]; out += 1; } }
    var result: [CODE_BYTES]u8 = @splat('1');
    for (0..@min(out, CODE_BYTES)) |i| result[i] = text[i];
    return result;
}

export fn caverphone_2_encoder(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_TEXT + 1) return -1;
    const count_value = input[0];
    if (count_value < 0 or count_value > MAX_TEXT or length != @as(usize, @intCast(count_value)) + 1) return -1;
    const count: usize = @intCast(count_value);
    for (0..count) |i| {
        const code = input[i + 1];
        if (!((code >= 65 and code <= 90) or (code >= 97 and code <= 122))) return -1;
    }
    if (output == null or output_capacity < CODE_BYTES) return -2;
    const result = encode(input);
    for (0..CODE_BYTES) |i| output[i] = result[i];
    return CODE_BYTES;
}
