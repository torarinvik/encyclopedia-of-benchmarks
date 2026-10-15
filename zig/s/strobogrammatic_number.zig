const MAX_INPUT_LENGTH: usize = 64;

fn rotated_digit(value: i64) i64 {
    return switch (value) {
        48 => 48,
        49 => 49,
        54 => 57,
        56 => 56,
        57 => 54,
        else => -1,
    };
}

export fn strobogrammatic_number(bytes: [*c]const i64, length: usize) i64 {
    if ((bytes == null and length != 0) or length > MAX_INPUT_LENGTH) return -1;
    var check_index: usize = 0;
    while (check_index < length) : (check_index += 1) {
        if (bytes[check_index] < 0 or bytes[check_index] > 127) return -1;
    }
    var left: usize = 0;
    var right = length;
    while (left < right) {
        const left_value = bytes[left];
        const right_value = bytes[right - 1];
        if (rotated_digit(left_value) != right_value) return 0;
        left += 1;
        right -= 1;
    }
    return 1;
}
