const MAX_N: usize = 64;
const MAX_STRIDE: usize = 4;
const MAX_PHYSICAL_N: usize = 1 + (MAX_N - 1) * MAX_STRIDE;
const MAX_INPUT_LENGTH: usize = 2 + MAX_PHYSICAL_N;
const MAX_VALUE: i64 = 1_000_000;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s318_strided_absolute_maximum_with_index(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    const stride_raw = values[1];
    if (n_raw < 1 or n_raw > MAX_N or stride_raw < 1 or stride_raw > MAX_STRIDE) return -1;
    const n: usize = @intCast(n_raw);
    const stride: usize = @intCast(stride_raw);
    const physical_n = 1 + (n - 1) * stride;
    if (length != 2 + physical_n) return -1;
    for (values[2..]) |value| {
        if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
    }
    if (output == null or output_capacity < 16) return -2;

    var maximum = if (values[2] < 0) -values[2] else values[2];
    var maximum_index: usize = 0;
    for (1..n) |i| {
        const value = values[2 + i * stride];
        const magnitude = if (value < 0) -value else value;
        if (magnitude > maximum) {
            maximum = magnitude;
            maximum_index = i;
        }
    }
    storeI64Le(output, 0, maximum);
    storeI64Le(output, 8, @intCast(maximum_index));
    return 2;
}
