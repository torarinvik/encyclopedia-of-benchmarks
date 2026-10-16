const max_code_units: i64 = 1024;

/// mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units.
export fn string_prefix_suffix(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3 or length > 2052) return -1;
    const mode = values[0];
    const text_count_value = values[1];
    const pattern_count_value = values[2];
    if ((mode != 0 and mode != 1) or text_count_value < 0 or text_count_value > max_code_units or
        pattern_count_value < 0 or pattern_count_value > max_code_units) return -1;
    const text_count: usize = @intCast(text_count_value);
    const pattern_count: usize = @intCast(pattern_count_value);
    if (length != 3 + text_count + pattern_count) return -1;
    for (0..text_count + pattern_count) |index| {
        const unit = values[3 + index];
        if (unit < 0 or unit > 65535) return -1;
    }
    if (pattern_count > text_count) return 0;
    const start: usize = if (mode == 0) 0 else text_count - pattern_count;
    for (0..pattern_count) |index| {
        if (values[3 + start + index] != values[3 + text_count + index]) return 0;
    }
    return 1;
}
