const MAX_LENGTH: usize = 4096;

export fn is_uppercase(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        const value = values[index];
        if (value < 32 or value > 126) return -1;
        if (value >= 97 and value <= 122) return 0;
    }
    return 1;
}
