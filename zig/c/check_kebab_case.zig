const MAX_LENGTH: usize = 4096;

fn isAsciiWord(value: i64) bool {
    return (value >= 97 and value <= 122) or (value >= 65 and value <= 90) or
        (value >= 48 and value <= 57);
}

pub export fn check_kebab_case(values: [*]const i64, length: usize) i64 {
    if (length > MAX_LENGTH) return -2;
    for (0..length) |index| {
        if (values[index] < 32 or values[index] > 126) return -2;
    }
    for (0..length) |index| {
        if (values[index] == 95) return 0;
    }
    if (length < 3) return 0;
    for (1..length - 1) |index| {
        if (values[index] == 45 and isAsciiWord(values[index - 1]) and isAsciiWord(values[index + 1])) return 1;
    }
    return 0;
}
