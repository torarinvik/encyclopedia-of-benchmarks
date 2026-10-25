const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_N;
const MAX_VALUE: i64 = 2;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s319_coupled_reductions(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + 3 * n) return -1;

    const c_start = 1;
    const d_start = c_start + n;
    const e_start = d_start + n;
    for (0..n) |i| {
        if (values[c_start + i] < -MAX_VALUE or values[c_start + i] > MAX_VALUE or
            values[d_start + i] < -MAX_VALUE or values[d_start + i] > MAX_VALUE or
            values[e_start + i] < -MAX_VALUE or values[e_start + i] > MAX_VALUE) return -1;
    }
    const value_count = 2 * n + 1;
    if (output == null or output_capacity < 8 * value_count) return -2;

    var total: i64 = 0;
    for (0..n) |i| {
        const a_value = values[c_start + i] + values[d_start + i];
        const b_value = values[c_start + i] + values[e_start + i];
        storeI64Le(output, 8 * i, a_value);
        storeI64Le(output, 8 * (n + i), b_value);
        total += a_value;
        total += b_value;
    }
    storeI64Le(output, 8 * (2 * n), total);
    return @intCast(value_count);
}
