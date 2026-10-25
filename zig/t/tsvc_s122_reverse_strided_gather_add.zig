// Clean-room port of TSVC s122; see package README for provenance and rights.
const MAX_N: usize = 32;
const MAX_INPUT_LENGTH: usize = 67;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s122_reverse_strided_gather_add(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    if (values[1] < 1 or values[1] > @as(i64, @intCast(n)) or
        values[2] < 1 or values[2] > @as(i64, @intCast(n))) return -1;
    if (length != 3 + 2 * n) return -1;
    const start: usize = @intCast(values[1]);
    const stride: usize = @intCast(values[2]);
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[3 + i];
        b[i] = values[3 + n + i];
        if (a[i] < -100 or a[i] > 100 or b[i] < -100 or b[i] > 100) return -1;
    }
    if (output == null or output_capacity < 8 * n) return -2;
    var j: usize = 1;
    var k: usize = 0;
    var i = start - 1;
    while (i < n) : (i += stride) {
        k += j;
        a[i] += b[n - k];
    }
    for (0..n) |index| storeI64Le(output, 8 * index, a[index]);
    return @intCast(n);
}
