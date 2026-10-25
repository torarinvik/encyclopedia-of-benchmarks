// Clean-room port of TSVC s128; see package README for provenance and rights.
const MAX_N: usize = 16;
const MAX_INPUT_LENGTH: usize = 1 + 5 * MAX_N;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s128_strided_coupled_update(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    const b_count = 2 * n;
    if (length != 1 + 5 * n) return -1;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** (2 * MAX_N);
    var c = [_]i64{0} ** (2 * MAX_N);
    var d = [_]i64{0} ** MAX_N;
    for (0..b_count) |i| {
        b[i] = values[1 + i];
        c[i] = values[1 + b_count + i];
        if (b[i] < -100 or b[i] > 100 or c[i] < -100 or c[i] > 100) return -1;
    }
    for (0..n) |i| {
        d[i] = values[1 + 2 * b_count + i];
        if (d[i] < -100 or d[i] > 100) return -1;
    }
    const output_values = 3 * n;
    const output_bytes = 8 * output_values;
    if (output == null or output_capacity < output_bytes) return -2;
    var j: i64 = -1;
    for (0..n) |i| {
        const k: usize = @intCast(j + 1);
        a[i] = b[k] - d[i];
        j = @as(i64, @intCast(k)) + 1;
        b[k] = a[i] + c[k];
    }
    for (0..n) |i| storeI64Le(output, 8 * i, a[i]);
    for (0..b_count) |i| storeI64Le(output, 8 * (n + i), b[i]);
    return @intCast(output_values);
}
