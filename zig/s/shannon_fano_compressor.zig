const std = @import("std");
const max_text = 16;
const max_symbols = 16;
const max_code = 15;
const max_output = 514;
const Codes = [128][max_code]u8;
const Lengths = [128]u8;

fn makeCodes(symbols: []const u8, freq: *const [128]f64, prefix: *[max_code]u8, depth: usize,
    codes: *Codes, lengths: *Lengths) bool {
    if (symbols.len == 1) {
        const s = symbols[0];
        @memcpy(codes[s][0..depth], prefix[0..depth]);
        lengths[s] = @intCast(depth);
        return true;
    }
    var total: f64 = 0;
    for (symbols) |s| total += freq[s];
    const capacity = 0.5 * total;
    var running: f64 = 0;
    var left: [max_symbols]u8 = undefined;
    var right: [max_symbols]u8 = undefined;
    var nl: usize = 0;
    var nr: usize = 0;
    for (symbols) |s| {
        if (running + freq[s] <= capacity) { left[nl] = s; nl += 1; running += freq[s]; }
        else { right[nr] = s; nr += 1; }
    }
    if (nl == 0 or nr == 0 or depth >= max_code) return false;
    prefix[depth] = '0';
    if (!makeCodes(left[0..nl], freq, prefix, depth + 1, codes, lengths)) return false;
    prefix[depth] = '1';
    return makeCodes(right[0..nr], freq, prefix, depth + 1, codes, lengths);
}

export fn shannon_fano_compressor(input: ?[*]const i64, input_length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input_length > 18 or (input == null and input_length != 0) or (input != null and input_length == 0)) return -1;
    const values = input;
    var text_length: usize = 0;
    if (values) |p| {
        if (p[0] < 0 or p[0] > max_text) return -1;
        text_length = @intCast(p[0]);
        if (input_length != text_length + 1) return -1;
    }
    var text: [max_text]u8 = undefined;
    var symbols: [max_symbols]u8 = undefined;
    var counts = [_]usize{0} ** 128;
    var seen = [_]bool{false} ** 128;
    var symbol_count: usize = 0;
    if (values) |p| {
        for (0..text_length) |i| {
            const value = p[i + 1];
            if (value < 0 or value > 127) return -1;
            const s: usize = @intCast(value);
            text[i] = @intCast(s);
            if (!seen[s]) {
                seen[s] = true;
                symbols[symbol_count] = @intCast(s);
                symbol_count += 1;
            }
            counts[s] += 1;
        }
    }
    var freq = [_]f64{0} ** 128;
    if (text_length != 0) {
        for (0..128) |s| {
            freq[s] = (1.0 * @as(f64, @floatFromInt(counts[s]))) / @as(f64, @floatFromInt(text_length));
        }
    }
    var codes: Codes = @splat(@splat(0));
    var lengths: Lengths = @splat(0);
    if (symbol_count == 1) { codes[symbols[0]][0] = '1'; lengths[symbols[0]] = 1; }
    else if (symbol_count > 1) {
        var prefix: [max_code]u8 = undefined;
        if (!makeCodes(symbols[0..symbol_count], &freq, &prefix, 0, &codes, &lengths)) return -1;
    }
    var staged: [max_output]u8 = undefined;
    var n: usize = 0;
    var compressed_length: usize = 0;
    for (text[0..text_length]) |s| compressed_length += lengths[s];
    staged[n] = @intCast(compressed_length); n += 1;
    for (text[0..text_length]) |s| { const len = lengths[s]; @memcpy(staged[n..][0..len], codes[s][0..len]); n += len; }
    staged[n] = @intCast(symbol_count); n += 1;
    for (0..128) |s| { const len = lengths[s]; if (len != 0) { staged[n] = @intCast(s); n += 1; staged[n] = len; n += 1; @memcpy(staged[n..][0..len], codes[s][0..len]); n += len; } }
    const out = output orelse return -2;
    if (capacity < n) return -2;
    @memcpy(out[0..n], staged[0..n]);
    return @intCast(n);
}
