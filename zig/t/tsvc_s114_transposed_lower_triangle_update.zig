// Clean-room port of TSVC s114; see package README for provenance and rights.
const MAX_N: usize = 16;
const MAX_INPUT_LENGTH: usize = 1 + 2 * MAX_N * MAX_N;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s114_transposed_lower_triangle_update(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 9 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 2 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    const cells = n * n;
    if (length != 1 + 2 * cells) return -1;
    var a = [_]i64{0} ** (MAX_N * MAX_N);
    var b = [_]i64{0} ** (MAX_N * MAX_N);
    for (0..cells) |i| {
        a[i] = values[1 + i];
        b[i] = values[1 + cells + i];
        if (a[i] < -1_000_000 or a[i] > 1_000_000 or b[i] < -1_000_000 or b[i] > 1_000_000) return -1;
    }
    const output_bytes = 8 * cells;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..n) |i| {
        for (0..i) |j| {
            a[i * n + j] = a[j * n + i] + b[i * n + j];
        }
    }
    for (0..cells) |i| storeI64Le(output, 8 * i, a[i]);
    return @intCast(cells);
}
