// Modified derivative of MiBench bmhsrch.c; public domain by Raymond Gardner (7/92).
const MAX_TEXT: usize = 128;
const MAX_PATTERN: usize = 32;
const MAX_INPUT: usize = 162;

export fn mibench_office_stringsearch_bmh(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const text_len_value = input[0];
    const pattern_len_value = input[1];
    if (text_len_value < 0 or text_len_value > MAX_TEXT or
        pattern_len_value < 1 or pattern_len_value > MAX_PATTERN) return -1;
    const text_len: usize = @intCast(text_len_value);
    const pattern_len: usize = @intCast(pattern_len_value);
    if (length != 2 + text_len + pattern_len) return -1;
    var text: [MAX_TEXT]u8 = @splat(0);
    var pattern: [MAX_PATTERN]u8 = @splat(0);
    for (0..text_len + pattern_len) |i| {
        const value = input[2 + i];
        if (value < 32 or value > 126) return -1;
        if (i < text_len) text[i] = @intCast(value) else pattern[i - text_len] = @intCast(value);
    }
    var shift: [256]usize = @splat(pattern_len);
    for (0..pattern_len - 1) |i| shift[pattern[i]] = pattern_len - i - 1;
    var match_offset: i64 = -1;
    if (pattern_len <= text_len) {
        var start: usize = 0;
        while (start <= text_len - pattern_len) {
            var j = pattern_len;
            while (j > 0 and text[start + j - 1] == pattern[j - 1]) j -= 1;
            if (j == 0) {
                match_offset = @intCast(start);
                break;
            }
            start += shift[text[start + pattern_len - 1]];
        }
    }
    if (output == null or output_capacity < 8) return -2;
    const bits: u64 = @bitCast(match_offset);
    for (0..8) |i| output[i] = @truncate(bits >> @intCast(8 * i));
    return 8;
}
