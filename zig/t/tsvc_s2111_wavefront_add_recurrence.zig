const MAX_SIDE: usize = 8;
const MAX_PASSES: usize = 4;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;
const MAX_INPUT_LENGTH: usize = 2 + MAX_CELLS;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

/// Clean-room bounded profile of TSVC s2111; see package README.
export fn tsvc_s2111_wavefront_add_recurrence(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 6 or length > MAX_INPUT_LENGTH) return -1;
    const values = input[0..length];
    const side_raw = values[0];
    const passes_raw = values[1];
    if (side_raw < 2 or side_raw > MAX_SIDE or passes_raw < 1 or passes_raw > MAX_PASSES) return -1;
    const side: usize = @intCast(side_raw);
    const cells = side * side;
    if (length != 2 + cells) return -1;

    var matrix = [_]i64{0} ** MAX_CELLS;
    for (0..cells) |cell| {
        const value = values[2 + cell];
        if (value < -8 or value > 8) return -1;
        matrix[cell] = value;
    }
    if (output == null or output_capacity < 8 * cells) return -2;

    for (0..@intCast(passes_raw)) |_| {
        for (1..side) |row| {
            for (1..side) |col| {
                matrix[row * side + col] = matrix[row * side + col - 1] + matrix[(row - 1) * side + col];
            }
        }
    }
    for (0..cells) |cell| storeI64Le(output, 8 * cell, matrix[cell]);
    return @intCast(cells);
}
