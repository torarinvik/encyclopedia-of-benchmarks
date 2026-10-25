// Clean-room port of TSVC s244; see package README for provenance and rights.
const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 129;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s244_false_dependence_cycle_break(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 9 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 2 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 4 * n) return -1;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    var d = [_]i64{0} ** MAX_N;
    var trace = [_]i64{0} ** (MAX_N - 1);
    for (0..n) |i| {
        a[i] = values[1 + i];
        b[i] = values[1 + n + i];
        c[i] = values[1 + 2 * n + i];
        d[i] = values[1 + 3 * n + i];
        if (a[i] < -2 or a[i] > 2 or b[i] < -2 or b[i] > 2 or
            c[i] < -2 or c[i] > 2 or d[i] < -2 or d[i] > 2) return -1;
    }
    const output_values = 3 * n - 1;
    if (output == null or output_capacity < 8 * output_values) return -2;
    for (0..n - 1) |i| {
        a[i] = b[i] + c[i] * d[i];
        b[i] = c[i] + b[i];
        a[i + 1] = b[i] + a[i + 1] * d[i];
        trace[i] = a[i + 1];
    }
    var offset: usize = 0;
    for (0..n) |i| {
        storeI64Le(output, 8 * offset, a[i]);
        offset += 1;
    }
    for (0..n) |i| {
        storeI64Le(output, 8 * offset, b[i]);
        offset += 1;
    }
    for (0..n - 1) |i| {
        storeI64Le(output, 8 * offset, trace[i]);
        offset += 1;
    }
    return @intCast(output_values);
}
