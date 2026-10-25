const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_N;

fn boundedValue(value: i64) bool { return value >= -1 and value <= 1; }

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s322_second_order_recurrence(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 7 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 2 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    if (length != 1 + 3 * n) return -1;

    const a_start = 1;
    const b_start = a_start + n;
    const c_start = b_start + n;
    for (0..n) |i| {
        if (!boundedValue(values[a_start + i]) or !boundedValue(values[b_start + i]) or
            !boundedValue(values[c_start + i])) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;

    var a: [MAX_N]i64 = [_]i64{0} ** MAX_N;
    @memcpy(a[0..n], values[a_start..b_start]);
    for (2..n) |i|
        a[i] += a[i - 1] * values[b_start + i] + a[i - 2] * values[c_start + i];
    for (0..n) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(n);
}
