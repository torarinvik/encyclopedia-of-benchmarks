const MAX_PATTERN_LENGTH: i64 = 63;
const MAX_TEXT_LENGTH: i64 = 4096;
const MAX_ERRORS: i64 = 2;

export fn agrep_approx_substring_count(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3) return -2;
    if (values[0] < 1 or values[0] > MAX_PATTERN_LENGTH or
        values[1] < 0 or values[1] > MAX_TEXT_LENGTH or values[2] < 0 or values[2] > MAX_ERRORS)
        return -2;
    const pattern_length: usize = @intCast(values[0]);
    const text_length: usize = @intCast(values[1]);
    if (length != 3 + pattern_length + text_length) return -2;
    for (3..length) |index| {
        if (values[index] < 32 or values[index] > 126) return -2;
    }

    var previous: [64]i64 = undefined;
    var current: [64]i64 = undefined;
    for (0..pattern_length + 1) |index| previous[index] = @intCast(index);
    var matches: i64 = 0;
    const text_offset = 3 + pattern_length;
    for (0..text_length) |text_index| {
        current[0] = 0;
        for (1..pattern_length + 1) |pattern_index| {
            const substitution = previous[pattern_index - 1] +
                (if (values[3 + pattern_index - 1] == values[text_offset + text_index]) @as(i64, 0) else @as(i64, 1));
            var best = previous[pattern_index] + 1;
            if (current[pattern_index - 1] + 1 < best) best = current[pattern_index - 1] + 1;
            if (substitution < best) best = substitution;
            current[pattern_index] = best;
        }
        if (current[pattern_length] <= values[2]) matches += 1;
        for (0..pattern_length + 1) |index| previous[index] = current[index];
    }
    return matches;
}
