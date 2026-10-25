const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N;
const MAX_VALUE: i64 = 1_000_000;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_vag_indexed_gather_copy(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + 2 * n) return -1;
    for (0..n) |i| {
        const index = values[1 + i];
        if (index < 0 or index >= n_raw) return -1;
        const value = values[1 + n + i];
        if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;

    for (0..n) |i| {
        const index: usize = @intCast(values[1 + i]);
        storeI64Le(output, 8 * i, values[1 + n + index]);
    }
    return @intCast(n);
}
