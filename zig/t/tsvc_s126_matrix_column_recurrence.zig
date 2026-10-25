// Clean-room port of TSVC s126; see package README for provenance and rights.
const MAX_N: usize = 6;
const MAX_CELLS: usize = MAX_N * MAX_N;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_CELLS;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s126_matrix_column_recurrence(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 13 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    if (values[0] < 2 or values[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(values[0]);
    const cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    var coefficients = [_]i64{0} ** MAX_CELLS;
    var c_matrix = [_]i64{0} ** MAX_CELLS;
    var b_matrix = [_]i64{0} ** MAX_CELLS;
    for (0..cells) |i| {
        coefficients[i] = values[1 + i];
        c_matrix[i] = values[1 + cells + i];
        b_matrix[i] = values[1 + 2 * cells + i];
        if (coefficients[i] < -100 or coefficients[i] > 100 or
            c_matrix[i] < -100 or c_matrix[i] > 100 or b_matrix[i] < -100 or b_matrix[i] > 100) return -1;
    }
    const output_bytes = 8 * cells;
    if (output == null or output_capacity < output_bytes) return -2;
    var k: usize = 1;
    for (0..n) |i| {
        var j: usize = 1;
        while (j < n) : (j += 1) {
            const target = j * n + i;
            b_matrix[target] = b_matrix[target - n] + coefficients[k - 1] * c_matrix[target];
            k += 1;
        }
        k += 1;
    }
    for (0..cells) |i| storeI64Le(output, 8 * i, b_matrix[i]);
    return @intCast(cells);
}
