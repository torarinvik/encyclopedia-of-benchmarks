const MAX_LENGTH: usize = 1024;

fn lowerAscii(value: i64) i64 {
    return if (value >= 65 and value <= 90) value + 32 else value;
}

export fn check_palindrome2(
    values: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    output_capacity: usize,
) i64 {
    if (length > MAX_LENGTH or (length != 0 and values == null)) return -1;
    const input = if (length == 0) &[_]i64{} else values.?[0..length];
    for (input) |value| if (value < 32 or value > 126) return -1;
    var start: usize = 0;
    var end = length;
    while (start < end and input[start] == 32) : (start += 1) {}
    while (end > start and input[end - 1] == 32) : (end -= 1) {}
    const normalized = input[start..end];
    if (normalized.len == 0 or (normalized.len == 1 and normalized[0] == 48)) return -1;

    var palindrome = true;
    for (0..normalized.len / 2) |left| {
        const right = normalized.len - left - 1;
        if (lowerAscii(normalized[left]) != lowerAscii(normalized[right])) palindrome = false;
    }
    const suffix = if (palindrome) " - a palindrome string.\n" else " - not a palindrome string.\n";
    const required = normalized.len + suffix.len;
    if (output == null or output_capacity < required) return -2;
    const result = output.?[0..output_capacity];
    for (normalized, 0..) |value, index| result[index] = @intCast(lowerAscii(value));
    for (suffix, 0..) |byte, index| result[normalized.len + index] = byte;
    return @intCast(required);
}
