const MAX_LENGTH: usize = 4096;

fn isAsciiLetter(value: u8) bool {
    return (value >= 'A' and value <= 'Z') or (value >= 'a' and value <= 'z');
}

export fn reverse_only_letters(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length > MAX_LENGTH) return -1;
    for (0..length) |index| {
        if (input[index] < 32 or input[index] > 126) return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| output[index] = @intCast(input[index]);

    var left: usize = 0;
    var right = length;
    while (left < right) {
        if (!isAsciiLetter(output[left])) {
            left += 1;
        } else if (!isAsciiLetter(output[right - 1])) {
            right -= 1;
        } else {
            const temporary = output[left];
            output[left] = output[right - 1];
            output[right - 1] = temporary;
            left += 1;
            right -= 1;
        }
    }
    return @intCast(length);
}
