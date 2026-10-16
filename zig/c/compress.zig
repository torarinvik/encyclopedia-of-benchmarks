const MAX_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = MAX_LENGTH + 1;
const BYTES_PER_VALUE: usize = 4;

fn storeI32Le(output: [*c]u8, position: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..BYTES_PER_VALUE) |byte|
        output[position + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn compress(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const packed_values = input[0..length];
    const count_value = packed_values[0];
    if (count_value < 0 or count_value > @as(i64, @intCast(MAX_LENGTH))) return -1;
    const count: usize = @intCast(count_value);
    if (length != 1 + count) return -1;
    const values = packed_values[1..];
    for (values) |value| if (value < -2147483648 or value > 2147483647) return -1;

    const maximum_bytes = count * BYTES_PER_VALUE;
    if (output_capacity < maximum_bytes or (maximum_bytes > 0 and output == null)) return -2;
    var result_count: usize = 0;
    var previous: i64 = 0;
    for (values, 0..) |value, index| {
        if (index == 0 or value != previous) {
            storeI32Le(output, result_count * BYTES_PER_VALUE, value);
            result_count += 1;
        }
        previous = value;
    }
    return @intCast(result_count);
}
