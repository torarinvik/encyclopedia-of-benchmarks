const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + MAX_N;
const MAX_VALUE: i64 = 1_000_000;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s291_cyclic_neighbor_average(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 2 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + n) return -1;
    for (values[1..]) |value| {
        if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;

    for (0..n) |i| {
        const previous = if (i == 0) n - 1 else i - 1;
        storeI64Le(output, 8 * i, values[i + 1] + values[previous + 1]);
    }
    return @intCast(n);
}
