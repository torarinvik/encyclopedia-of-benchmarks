const MAX_LENGTH: usize = 4096;

/// Return whether any lowercase ASCII vowel appears in the input.
export fn check_vowels(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    if (length == 0) return 0;
    const data = values[0..length];
    for (data) |value| {
        if (value < 97 or value > 122) return -1;
    }
    for (data) |value| {
        if (value == 97 or value == 101 or value == 105 or value == 111 or value == 117) return 1;
    }
    return 0;
}
