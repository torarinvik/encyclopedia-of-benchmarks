const MAX_LENGTH: usize = 1024;

fn isUpper(value: i64) bool { return value >= 65 and value <= 90; }
fn isLower(value: i64) bool { return value >= 97 and value <= 122; }

/// Recheck the whole word for every uppercase byte after the first.
export fn detect_capital_usage_scan(input: [*c]const i64, length: usize) i64 {
    if (length > MAX_LENGTH or (length != 0 and input == null)) return -1;
    for (0..length) |index| {
        const value = input[index];
        if (!isUpper(value) and !isLower(value)) return -1;
    }
    var index: usize = 1;
    while (index < length) : (index += 1) {
        if (isUpper(input[index])) {
            var all_upper = true;
            for (0..length) |check| {
                if (isLower(input[check])) { all_upper = false; break; }
            }
            if (!all_upper) return 0;
        }
    }
    return 1;
}
