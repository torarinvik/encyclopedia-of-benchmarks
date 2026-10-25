const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 5 * MAX_N;
const MAX_VALUE: i64 = 2;

fn boundedValue(value: i64) bool {
    return value >= -MAX_VALUE and value <= MAX_VALUE;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s161_mutually_exclusive_updates(input: [*c]const i64, length: usize,
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
    var c = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[a_start + i];
        c[i] = values[c_start + i];
        if (!boundedValue(a[i]) or !boundedValue(values[b_start + i]) or
            !boundedValue(c[i]) or !boundedValue(values[d_start + i]) or
            !boundedValue(values[e_start + i])) return -1;
    }
    if (output == null or output_capacity < 16 * n) return -2;

    for (0..n - 1) |i| {
        if (values[b_start + i] < 0) {
            const d = values[d_start + i];
            c[i + 1] = a[i] + d * d;
        } else {
            a[i] = c[i] + values[d_start + i] * values[e_start + i];
        }
    }
    for (0..n) |i| {
        storeI64Le(output, 8 * i, a[i]);
        storeI64Le(output, 8 * (n + i), c[i]);
    }
    return @intCast(2 * n);
}
