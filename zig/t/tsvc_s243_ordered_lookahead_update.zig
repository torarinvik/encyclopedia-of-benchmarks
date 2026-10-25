const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 5 * MAX_N;
const MAX_VALUE: i64 = 2;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s243_ordered_lookahead_update(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 11 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 2 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + 5 * n) return -1;

    const a_start = 1;
    const b_start = a_start + n;
    const c_start = b_start + n;
    const d_start = c_start + n;
    const e_start = d_start + n;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[a_start + i];
        b[i] = values[b_start + i];
        if (a[i] < -MAX_VALUE or a[i] > MAX_VALUE or
            b[i] < -MAX_VALUE or b[i] > MAX_VALUE or
            values[c_start + i] < -MAX_VALUE or values[c_start + i] > MAX_VALUE or
            values[d_start + i] < -MAX_VALUE or values[d_start + i] > MAX_VALUE or
            values[e_start + i] < -MAX_VALUE or values[e_start + i] > MAX_VALUE) return -1;
    }
    if (output == null or output_capacity < 16 * n) return -2;

    for (0..(n - 1)) |i| {
        const next_a = a[i + 1];
        const d_value = values[d_start + i];
        a[i] = b[i] + values[c_start + i] * d_value;
        b[i] = a[i] + d_value * values[e_start + i];
        a[i] = b[i] + next_a * d_value;
    }
    for (0..n) |i| {
        storeI64Le(output, 8 * i, a[i]);
        storeI64Le(output, 8 * (n + i), b[i]);
    }
    return @intCast(2 * n);
}
