const MAX_N: usize = 8;
const MAX_CELLS: usize = MAX_N * MAX_N;
const MAX_INPUT_LENGTH: usize = 1 + 3 * MAX_CELLS;
const MAX_VALUE: i64 = 100;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn tsvc_s2101_diagonal_matrix_fma(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const n_raw = values[0];
    if (n_raw < 1 or n_raw > MAX_N) return -1;
    const n: usize = @intCast(n_raw);
    const cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (values[1..]) |value| {
        if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
    }
    if (output == null or output_capacity < 8 * cells) return -2;

    for (0..cells) |cell| storeI64Le(output, 8 * cell, values[cell + 1]);
    for (0..n) |i| {
        const diagonal = i * n + i;
        const value = values[1 + diagonal]
            + values[1 + cells + diagonal] * values[1 + 2 * cells + diagonal];
        storeI64Le(output, 8 * diagonal, value);
    }
    return @intCast(cells);
}
