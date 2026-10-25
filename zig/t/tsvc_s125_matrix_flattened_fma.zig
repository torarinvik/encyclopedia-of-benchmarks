// Clean-room port of TSVC s125; see package README for provenance and rights.
const MAX_N: usize = 8;
const MAX_CELLS: usize = MAX_N * MAX_N;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_CELLS;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s125_matrix_flattened_fma(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    const cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    var aa = [_]i64{0} ** MAX_CELLS;
    var bb = [_]i64{0} ** MAX_CELLS;
    var cc = [_]i64{0} ** MAX_CELLS;
    var result = [_]i64{0} ** MAX_CELLS;
    for (0..cells) |i| {
        aa[i] = values[1 + i];
        bb[i] = values[1 + cells + i];
        cc[i] = values[1 + 2 * cells + i];
        if (aa[i] < -100 or aa[i] > 100 or bb[i] < -100 or bb[i] > 100 or cc[i] < -100 or cc[i] > 100) return -1;
    }
    const output_bytes = 8 * cells;
    if (output == null or output_capacity < output_bytes) return -2;
    var k: usize = 0;
    for (0..n) |_| {
        for (0..n) |_| {
            result[k] = aa[k] + bb[k] * cc[k];
            k += 1;
        }
    }
    for (0..cells) |i| storeI64Le(output, 8 * i, result[i]);
    return @intCast(cells);
}
