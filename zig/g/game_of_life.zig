/// Compute one finite, non-wrapping Conway Game of Life generation.
const MAX_SIDE: i64 = 32;

export fn game_of_life(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length == 0 or input == null) return -1;
    const side_value = input[0];
    if (side_value < 0 or side_value > MAX_SIDE) return -1;
    const side: usize = @intCast(side_value);
    const cell_count = side * side;
    if (length != cell_count + 1) return -1;
    for (0..cell_count) |index| {
        if (input[index + 1] != 0 and input[index + 1] != 1) return -1;
    }
    if (output_capacity < cell_count or (cell_count != 0 and output == null)) return -2;

    for (0..side) |row| {
        for (0..side) |column| {
            var neighbors: usize = 0;
            var row_delta: i64 = -1;
            while (row_delta <= 1) : (row_delta += 1) {
                var column_delta: i64 = -1;
                while (column_delta <= 1) : (column_delta += 1) {
                    if (row_delta == 0 and column_delta == 0) continue;
                    const neighbor_row = @as(i64, @intCast(row)) + row_delta;
                    const neighbor_column = @as(i64, @intCast(column)) + column_delta;
                    if (neighbor_row >= 0 and neighbor_row < side_value and
                        neighbor_column >= 0 and neighbor_column < side_value and
                        input[1 + @as(usize, @intCast(neighbor_row)) * side +
                              @as(usize, @intCast(neighbor_column))] == 1) {
                        neighbors += 1;
                    }
                }
            }
            const index = row * side + column;
            const alive = input[index + 1] == 1;
            output[index] = @intFromBool((alive and (neighbors == 2 or neighbors == 3)) or
                                          (!alive and neighbors == 3));
        }
    }
    return @intCast(cell_count);
}
