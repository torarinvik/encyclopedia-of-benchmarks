const MAX_LENGTH: usize = 1024;

fn isUpper(value: i64) bool { return value >= 65 and value <= 90; }
fn isLower(value: i64) bool { return value >= 97 and value <= 122; }

/// Classify capitalization by counting uppercase letters.
export fn detect_capital_usage(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    var uppercase_count: usize = 0;
    for (0..length) |index| {
        const value = input[index];
        if (!isUpper(value) and !isLower(value)) return -1;
        if (isUpper(value)) uppercase_count += 1;
    }
    if (uppercase_count == 0 or uppercase_count == length or
        (uppercase_count == 1 and length != 0 and isUpper(input[0]))) return 1;
    return 0;
}
