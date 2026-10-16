module string_prefix_suffix;

const MAX_CODE_UNITS = 1024;

// mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units.
fn long string_prefix_suffix(long* values, usz length) @export("string_prefix_suffix") {
    if (values == null || length < 3 || length > 2052) return -1;
    long mode = values[0];
    long text_count_value = values[1];
    long pattern_count_value = values[2];
    if ((mode != 0 && mode != 1) || text_count_value < 0 || text_count_value > MAX_CODE_UNITS ||
        pattern_count_value < 0 || pattern_count_value > MAX_CODE_UNITS) return -1;
    usz text_count = (usz)text_count_value;
    usz pattern_count = (usz)pattern_count_value;
    if (length != 3 + text_count + pattern_count) return -1;
    for (usz index = 0; index < text_count + pattern_count; index++)
        if (values[3 + index] < 0 || values[3 + index] > 65535) return -1;
    if (pattern_count > text_count) return 0;
    usz start = mode == 0 ? 0 : text_count - pattern_count;
    for (usz index = 0; index < pattern_count; index++)
        if (values[3 + start + index] != values[3 + text_count + index]) return 0;
    return 1;
}
