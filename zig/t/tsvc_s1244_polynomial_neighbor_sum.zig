// Clean-room bounded port of TSVC s1244; see package README for provenance.
const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 129;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s1244_polynomial_neighbor_sum(input: [*c]const i64, length: usize,
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
    for (0..n - 1) |i| {
        const old_next_a = a[i + 1];
        a[i] = b[i] + c[i] * c[i] + b[i] * b[i] + c[i];
        d[i] = a[i] + old_next_a;
    }
    for (0..n) |i| {
        storeI64Le(output, 8 * i, a[i]);
        storeI64Le(output, 8 * (n + i), d[i]);
    }
    return @intCast(2 * n);
}
