/// Check whether the bounded ASCII input is entirely lowercase letters.
const MAX_LENGTH: usize = 4096;

export fn check_flat_case(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -2;
    for (0..length) |index| {
        const value = values[index];
        if (value < 32 or value > 126) return -2;
    }
    for (0..length) |index| {
        const value = values[index];
        if (value < 97 or value > 122) return 0;
    }
    return 1;
}
