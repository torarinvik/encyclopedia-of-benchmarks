// Clean-room port of TSVC s1221; see package README for provenance and rights.
const MIN_N: usize = 5;
const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 65;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s1221_lag4_add_recurrence(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 11 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < @as(i64, @intCast(MIN_N)) or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 2 * n) return -1;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[1 + i];
        b[i] = values[1 + n + i];
        if (a[i] < -10 or a[i] > 10 or b[i] < -10 or b[i] > 10) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;
    for (4..n) |i| b[i] = b[i - 4] + a[i];
    for (0..n) |i| storeI64Le(output, 8 * i, b[i]);
    return @intCast(n);
}
