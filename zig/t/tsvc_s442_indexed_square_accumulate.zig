// Clean-room bounded port of TSVC s442; see package README for provenance.
const MAX_N: usize = 64;
const MAX_PASSES: usize = 16;
const MAX_INPUT_LENGTH: usize = 386;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s442_indexed_square_accumulate(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 8 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N)) or
        values[1] < 1 or values[1] > @as(i64, @intCast(MAX_PASSES))) return -1;
    const n: usize = @intCast(values[0]);
    const passes: usize = @intCast(values[1]);
    if (length != 2 + 6 * n) return -1;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    var c = [_]i64{0} ** MAX_N;
    var d = [_]i64{0} ** MAX_N;
    var e = [_]i64{0} ** MAX_N;
    var selector = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        c[i] = values[2 + 2 * n + i];
        d[i] = values[2 + 3 * n + i];
        e[i] = values[2 + 4 * n + i];
        selector[i] = values[2 + 5 * n + i];
        if (a[i] < -2 or a[i] > 2 or b[i] < -2 or b[i] > 2 or
            c[i] < -2 or c[i] > 2 or d[i] < -2 or d[i] > 2 or
            e[i] < -2 or e[i] > 2 or selector[i] < 1 or selector[i] > 4) return -1;
    }
    if (output == null or capacity < 8 * n) return -2;
    for (0..passes) |_| {
        for (0..n) |i| {
            const selected = switch (selector[i]) {
                1 => b[i],
                2 => c[i],
                3 => d[i],
                else => e[i],
            };
            a[i] += selected * selected;
        }
    }
    for (0..n) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(n);
}
