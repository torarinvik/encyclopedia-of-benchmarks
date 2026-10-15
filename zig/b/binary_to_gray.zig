/// Convert an ASCII binary string to equal-width ASCII Gray code.
export fn binary_to_gray(bits: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length == 0 or length > 66) return -1;
    for (0..length) |index| {
        if (bits[index] != '0' and bits[index] != '1') return -1;
    }
    if (output_capacity < length) return -2;
    for (0..length) |index| {
        const current: i64 = bits[index] - '0';
        const previous: i64 = if (index == 0) 0 else bits[index - 1] - '0';
        output[index] = @intCast('0' + (current ^ previous));
    }
    return @intCast(length);
}
