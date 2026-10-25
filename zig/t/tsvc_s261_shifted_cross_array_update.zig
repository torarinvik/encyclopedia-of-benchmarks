// Clean-room bounded port of TSVC s261; see package README for provenance.
const MAX_N: usize = 64;
const MAX_INPUT_LENGTH: usize = 257;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s261_shifted_cross_array_update(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 9 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 2 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 4 * n) return -1;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    var d = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[1 + i];
        b[i] = values[1 + n + i];
        c[i] = values[1 + 2 * n + i];
        d[i] = values[1 + 3 * n + i];
        if (a[i] < -2 or a[i] > 2 or b[i] < -2 or b[i] > 2 or
            c[i] < -2 or c[i] > 2 or d[i] < -2 or d[i] > 2) return -1;
    }
    if (output == null or capacity < 16 * n) return -2;
    for (1..n) |i| {
        const temporary = a[i] + b[i];
        a[i] = temporary + c[i - 1];
        const product = c[i] * d[i];
        c[i] = product;
    }
    for (0..n) |i| {
        storeI64Le(output, 8 * i, a[i]);
        storeI64Le(output, 8 * (n + i), c[i]);
    }
    return @intCast(2 * n);
}
