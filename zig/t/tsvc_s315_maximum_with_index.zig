const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + MAX_N;
const MAX_VALUE: i64 = 1_000_000;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s315_maximum_with_index(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + n) return -1;
    for (0..n) |i| {
        if (values[i + 1] < -MAX_VALUE or values[i + 1] > MAX_VALUE) return -1;
    }
    if (output == null or output_capacity < 16) return -2;

    var maximum = values[1];
    var maximum_index: usize = 0;
    for (0..n) |i| {
        const value = values[i + 1];
        if (value > maximum) {
            maximum = value;
            maximum_index = i;
        }
    }
    storeI64Le(output, 0, maximum);
    storeI64Le(output, 8, @intCast(maximum_index));
    return 2;
}
