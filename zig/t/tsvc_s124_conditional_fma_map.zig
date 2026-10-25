// Clean-room port of TSVC s124; see package README for provenance and rights.
const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 1 + 4 * MAX_N;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s124_conditional_fma_map(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 4 * n) return -1;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    var d = [_]i64{0} ** MAX_N;
    var e = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        b[i] = values[1 + i];
        c[i] = values[1 + n + i];
        d[i] = values[1 + 2 * n + i];
        e[i] = values[1 + 3 * n + i];
        if (b[i] < -100 or b[i] > 100 or c[i] < -100 or c[i] > 100 or
            d[i] < -100 or d[i] > 100 or e[i] < -100 or e[i] > 100) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;
    var j: i64 = -1;
    for (0..n) |i| {
        if (b[i] > 0) {
            j += 1;
            a[@intCast(j)] = b[i] + d[i] * e[i];
        } else {
            j += 1;
            a[@intCast(j)] = c[i] + d[i] * e[i];
        }
    }
    for (0..n) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(n);
}
