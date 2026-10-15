/// Check whether lowercase source letters can be capitalized or deleted.
pub export fn abbreviation(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 258) return -1;
    const source_length_value = values[0];
    const target_length_value = values[1];
    if (source_length_value < 0 or source_length_value > 128 or
        target_length_value < 0 or target_length_value > 128) return -1;
    const source_length: usize = @intCast(source_length_value);
    const target_length: usize = @intCast(target_length_value);
    if (length != 2 + source_length + target_length) return -1;
    const source = values[2..][0..source_length];
    const target = values[2 + source_length ..][0..target_length];
    for (source) |value| {
        if (!((value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z'))) return -1;
    }
    for (target) |value| {
        if (value < 'A' or value > 'Z') return -1;
    }

    var current: [129]bool = @splat(false);
    var next: [129]bool = @splat(false);
    current[0] = true;
    for (source) |value| {
        @memset(next[0 .. target_length + 1], false);
        const uppercase = if (value >= 'a' and value <= 'z') value - ('a' - 'A') else value;
        for (0..target_length + 1) |target_index| {
            if (!current[target_index]) continue;
            if (value >= 'a' and value <= 'z') next[target_index] = true;
            if (target_index < target_length and uppercase == target[target_index]) {
                next[target_index + 1] = true;
            }
        }
        @memcpy(current[0 .. target_length + 1], next[0 .. target_length + 1]);
    }
    return if (current[target_length]) 1 else 0;
}
