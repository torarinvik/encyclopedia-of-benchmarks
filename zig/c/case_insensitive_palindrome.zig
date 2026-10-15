/// Check whether an ASCII string is a palindrome ignoring ASCII letter case.
fn asciiLower(value: i64) i64 {
    return if (value >= 65 and value <= 90) value + 32 else value;
}

export fn case_insensitive_palindrome(values: [*]const i64, length: usize) i64 {
    if (length > 4096) return -1;
    for (0..length) |index| {
        if (values[index] < 0 or values[index] > 127) return -1;
    }
    for (0..length / 2) |left| {
        if (asciiLower(values[left]) != asciiLower(values[length - 1 - left])) return 0;
    }
    return 1;
}
