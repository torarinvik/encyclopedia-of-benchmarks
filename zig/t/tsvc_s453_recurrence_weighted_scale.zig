// Clean-room port of TSVC s453; see package README for provenance and rights.
const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 33;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s453_recurrence_weighted_scale(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + n) return -1;
    var b = [_]i64{0} ** MAX_N;
    var a = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        b[i] = values[1 + i];
        if (b[i] < -100 or b[i] > 100) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;
    var s: i64 = 0;
    for (0..n) |i| {
        s += 2;
        a[i] = s * b[i];
    }
    for (0..n) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(n);
}
