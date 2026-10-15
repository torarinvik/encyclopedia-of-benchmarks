/// Check whether an ASCII letter string is case-insensitively sorted.
fn is_ascii_letter(value: i64) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z');
}

fn lowercase_ascii(value: i64) i64 {
    if (value >= 'A' and value <= 'Z') return value + 32;
    return value;
}

export fn alphabetical(values: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 127) return -1;
    }
    if (length == 0) return 0;
    var previous: i64 = -1;
    for (0..length) |index| {
        const value = values[index];
        if (!is_ascii_letter(value)) return 0;
        const current = lowercase_ascii(value);
        if (current < previous) return 0;
        previous = current;
    }
    return 1;
}
