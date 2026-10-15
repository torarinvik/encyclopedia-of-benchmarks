/// Check the bounded ASCII camel-case predicate.
const MAX_LENGTH: usize = 4096;

export fn check_camel_case(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -2;
    if (length == 0) return 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 32 or value > 126) return -2;
    }
    if (values[0] < 97 or values[0] > 122) return 0;
    for (0..length) |index| {
        const value = values[index];
        if (!((value >= 97 and value <= 122) or (value >= 65 and value <= 90))) return 0;
    }
    return 1;
}
