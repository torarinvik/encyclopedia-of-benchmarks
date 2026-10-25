const MAX_SIDE: usize = 8;
const MAX_PASSES: usize = 8;
const MAX_CELLS: usize = MAX_SIDE * MAX_SIDE;

fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

/// Clean-room bounded profile of TSVC s2102; see package README.
export fn tsvc_s2102_identity_matrix_initialize(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length != 2) return -1;
    const values = input[0..length];
    const side_raw = values[0];
    const passes_raw = values[1];
    if (side_raw < 1 or side_raw > MAX_SIDE or passes_raw < 1 or passes_raw > MAX_PASSES) return -1;
    const side: usize = @intCast(side_raw);
    const cells = side * side;
    if (output == null or output_capacity < 8 * cells) return -2;

    var matrix = [_]i64{0} ** MAX_CELLS;
    for (0..@intCast(passes_raw)) |_| {
        for (0..side) |col| {
            for (0..side) |row| matrix[row * side + col] = 0;
            matrix[col * side + col] = 1;
        }
    }
    for (0..cells) |cell| storeI64Le(output, 8 * cell, matrix[cell]);
    return @intCast(cells);
}
