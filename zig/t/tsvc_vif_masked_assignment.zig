const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N;
const MAX_VALUE: i64 = 2;

fn boundedValue(value: i64) bool {
    return value >= -MAX_VALUE and value <= MAX_VALUE;
}

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_vif_masked_assignment(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + 2 * n) return -1;

    const a_start = 1;
    const b_start = a_start + n;
    var a = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[a_start + i];
        if (!boundedValue(a[i]) or !boundedValue(values[b_start + i])) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;

    for (0..n) |i| {
        const value = values[b_start + i];
        if (value > 0) a[i] = value;
    }
    for (0..n) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(n);
}
