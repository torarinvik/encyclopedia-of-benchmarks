const MAX_TEXT: i64 = 512;
const MIN_PATTERN: i64 = 2;
const MAX_PATTERN: i64 = 64;
const MAX_INPUT: usize = 578;

export fn not_so_naive_search(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT) return -2;
    const raw_text = values[0];
    const raw_pattern = values[1];
    if (raw_text < 0 or raw_text > MAX_TEXT or raw_pattern < MIN_PATTERN or raw_pattern > MAX_PATTERN) return -2;
    const text_length: usize = @intCast(raw_text);
    const pattern_length: usize = @intCast(raw_pattern);
    if (length != 2 + text_length + pattern_length) return -2;
    const pattern_start = 2 + text_length;
    for (0..text_length + pattern_length) |i| {
        const byte = values[2 + i];
        if (byte < 0 or byte > 127) return -2;
    }
    if (pattern_length > text_length) return -1;

    const same_prefix = values[pattern_start] == values[pattern_start + 1];
    const mismatch_shift: usize = if (same_prefix) 2 else 1;
    const post_check_shift: usize = if (same_prefix) 1 else 2;
    var position: usize = 0;
    const last_start = text_length - pattern_length;
    while (position <= last_start) {
        if (values[pattern_start + 1] != values[2 + position + 1]) {
            position += mismatch_shift;
            continue;
        }
        var pattern_index: usize = 2;
        while (pattern_index < pattern_length and
               values[pattern_start + pattern_index] == values[2 + position + pattern_index])
            : (pattern_index += 1) {}
        if (pattern_index == pattern_length and values[pattern_start] == values[2 + position])
            return @intCast(position);
        position += post_check_shift;
    }
    return -1;
}
