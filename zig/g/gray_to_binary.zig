/// Convert a nonnegative reflected Gray-code integer to its binary integer.
export fn gray_to_binary(gray_value: i64) i64 {
    if (gray_value < 0) return -1;
    var binary: u64 = @intCast(gray_value);
    var remaining: u64 = binary >> 1;
    while (remaining != 0) {
        binary ^= remaining;
        remaining >>= 1;
    }
    return @intCast(binary);
}
