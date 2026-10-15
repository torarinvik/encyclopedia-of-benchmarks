/// Convert a uint16 value to lowercase digits in a base from 2 through 16.
const MAX_VALUE: i64 = 65535;
const SYMBOLS = "0123456789abcdef";

export fn int_to_string(packed_value: i64, output: [*]u8, output_capacity: usize) i64 {
	if (packed_value < 0) return -1;
	const value = @divTrunc(packed_value, 15);
	const base = @mod(packed_value, 15) + 2;
    if (value > MAX_VALUE) return -1;
    var digits: [16]u8 = undefined;
    var count: usize = 0;
    var remaining = value;
    while (true) {
        digits[count] = SYMBOLS[@intCast(@mod(remaining, base))];
        count += 1;
        remaining = @divTrunc(remaining, base);
        if (remaining == 0) break;
    }
    const required = count + 1;
    if (output_capacity < required) return -2;
    for (0..count) |index| output[index] = digits[count - index - 1];
    output[count] = 0;
    return @intCast(required);
}
