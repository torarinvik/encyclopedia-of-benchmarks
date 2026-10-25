// Clean-room port of TSVC s353; see package README for provenance and rights.
const MAX_N: usize = 20;
const MAX_INPUT_LENGTH: usize = 2 + 3 * MAX_N;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s353_unrolled_sparse_saxpy(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 17 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 5 or values[0] > @as(i64, @intCast(MAX_N)) or values[0] % 5 != 0) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 2 + 3 * n) return -1;
    const alpha = values[1];
    if (alpha < -8 or alpha > 8) return -1;
    var a = [_]i64{0} ** MAX_N;
    var b = [_]i64{0} ** MAX_N;
    var indices = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        a[i] = values[2 + i];
        b[i] = values[2 + n + i];
        indices[i] = values[2 + 2 * n + i];
        if (a[i] < -1_000_000 or a[i] > 1_000_000 or b[i] < -1_000_000 or b[i] > 1_000_000 or
            indices[i] < 0 or indices[i] >= @as(i64, @intCast(n))) return -1;
    }
    const output_bytes = 8 * n;
    if (output == null or output_capacity < output_bytes) return -2;
    var i: usize = 0;
    while (i < n) : (i += 5) {
        a[i] += alpha * b[@intCast(indices[i])];
        a[i + 1] += alpha * b[@intCast(indices[i + 1])];
        a[i + 2] += alpha * b[@intCast(indices[i + 2])];
        a[i + 3] += alpha * b[@intCast(indices[i + 3])];
        a[i + 4] += alpha * b[@intCast(indices[i + 4])];
    }
    for (0..n) |position| storeI64Le(output, 8 * position, a[position]);
    return @intCast(n);
}
