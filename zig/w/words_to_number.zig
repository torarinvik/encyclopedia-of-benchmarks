const MAX_INPUT: usize = 128;
const MAX_TOKENS: usize = 128;
const WORDS = [_][]const u8{
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine",
    "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen",
    "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety", "hundred", "thousand",
    "million", "billion", "trillion", "and", "point", "negative",
};
fn word_id(input: [*]const i64, start: usize, end: usize) i64 {
    for (WORDS, 0..) |word, index| {
        if (word.len != end - start) continue;
        var matched = true;
        for (word, 0..) |expected, offset| {
            var ch: u8 = @intCast(input[1 + start + offset]);
            if (ch >= 'A' and ch <= 'Z') ch += 32;
            if (ch != expected) { matched = false; break; }
        }
        if (matched) return @intCast(index + 1);
    }
    return 0;
}
fn number_value(id: i64) i64 {
    if (id >= 1 and id <= 20) return id - 1;
    if (id >= 21 and id <= 28) return (id - 19) * 10;
    return -1;
}
fn digits10(value: i64) usize {
    var x = value; var count: usize = 1;
    while (x >= 10) { x = @divTrunc(x, 10); count += 1; }
    return count;
}
fn append_uint(out: []u8, at: *usize, value: i64) void {
    var reversed: [24]u8 = undefined; var used: usize = 0; var x = value;
    while (true) { reversed[used] = '0' + @as(u8, @intCast(@mod(x, 10))); used += 1; x = @divTrunc(x, 10); if (x == 0) break; }
    while (used > 0) { used -= 1; out[at.*] = reversed[used]; at.* += 1; }
}
fn is_separator(value: i64) bool { return value == 32 or value == 44 or value == 45; }
fn parse(input: [*]const i64, byte_count: usize, text: []u8) i64 {
    var tokens: [MAX_TOKENS]i64 = undefined; var count: usize = 0; var start: usize = MAX_INPUT + 1;
    for (0..byte_count) |i| {
        const value = input[1 + i]; if (value < 32 or value > 126) return -1;
        if (is_separator(value)) { if (start != MAX_INPUT + 1) { if (count >= MAX_TOKENS) return -1; tokens[count] = word_id(input, start, i); count += 1; start = MAX_INPUT + 1; } }
        else if (start == MAX_INPUT + 1) { start = i; }
    }
    if (start != MAX_INPUT + 1) { if (count >= MAX_TOKENS) return -1; tokens[count] = word_id(input, start, byte_count); count += 1; }
    if (count == 0) return -3;
    const negative = tokens[0] == 36; const pos: usize = if (negative) 1 else 0;
    var chunks: [MAX_TOKENS]i64 = undefined; var chunk_count: usize = 0; var current: i64 = 0; var prev_hundred = false; var prev_scale = false;
    var fraction: [16]u8 = undefined; var fraction_len: usize = 0; var has_point = false;
    for (pos..count) |i| {
        const id = tokens[i];
        if (id == 34) {
            if (i + 1 >= count) return -10; const value = number_value(tokens[i + 1]); const after: i64 = if (i + 2 < count) tokens[i + 2] else -1;
            if ((!prev_hundred and !prev_scale) or value < 0 or !(value >= 10 or after == -1 or after == 35)) return -10;
            continue;
        }
        if (id == 29) { if (current >= 10 or prev_scale) return -5; if (current == 0) current = 1; current *= 100; prev_hundred = true; continue; }
        prev_hundred = false;
        if (id >= 30 and id <= 33) {
            if (current == 0 or prev_scale) return -5;
            const scale: i64 = if (id == 30) 1000 else if (id == 31) 1000000 else if (id == 32) 1000000000 else 1000000000000;
            const next = current * scale;
            if (chunk_count > 0 and digits10(chunks[chunk_count - 1]) <= digits10(next)) return -5;
            chunks[chunk_count] = next; chunk_count += 1; current = 0; prev_scale = true; continue;
        }
        prev_scale = false;
        const value = number_value(id);
        if (value >= 0) { if (value == 0 and !(current == 0 and chunk_count == 0)) return -5; if (current != 0 and digits10(current) <= digits10(value)) return -5; current += value; continue; }
        if (id == 35) {
            if (current != 0) { chunks[chunk_count] = current; chunk_count += 1; }
            current = 0; has_point = true; var words: usize = 0;
            for (i + 1..count) |j| { const digit = number_value(tokens[j]); if (digit < 0) return -6; words += 1; if (words > 3) return -1; append_uint(fraction[0..], &fraction_len, digit); }
            if (words == 0) return -7; break;
        }
        if (id == 36) return if (negative) -8 else -9;
        return -4;
    }
    if (current != 0) { chunks[chunk_count] = current; chunk_count += 1; }
    var total: i64 = 0; for (0..chunk_count) |i| total += chunks[i];
    var fraction_nonzero = false; for (0..fraction_len) |i| { if (fraction[i] != '0') fraction_nonzero = true; }
    var out: usize = 0;
    if (negative and (total != 0 or fraction_nonzero)) { text[out] = '-'; out += 1; }
    append_uint(text, &out, total);
    if (has_point) { text[out] = '.'; out += 1; for (0..fraction_len) |i| { text[out] = fraction[i]; out += 1; } }
    return @intCast(out);
}
export fn words_to_number(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT + 1) return -1;
    const input_ptr = input.?;
    const n = input_ptr[0]; if (n < 0 or n > MAX_INPUT or length != @as(usize, @intCast(n + 1))) return -1;
    var text: [64]u8 = undefined; const result = parse(input_ptr, @intCast(n), text[0..]);
    if (result < 0) return result;
    const size: usize = @intCast(result); if (output == null or capacity < size) return -2;
    const output_ptr = output.?;
    for (0..size) |i| output_ptr[i] = text[i];
    return result;
}
