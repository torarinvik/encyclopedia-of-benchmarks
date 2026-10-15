const MAX_LENGTH: usize = 4096;

pub export fn check_snake_case(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -2;
    var found: i64 = 0;
    for (0..length) |index| {
        const value = values[index];
        if (value < 32 or value > 126) return -2;
        if (value == 95) found = 1;
    }
    return found;
}
