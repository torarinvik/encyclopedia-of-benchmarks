const MAX_DIMENSION: usize = 63;
const MAX_INPUT_VALUES: usize = 2 + MAX_DIMENSION * MAX_DIMENSION;

fn writeI32Le(output: []u8, offset: usize, value: i64) void {
    const signed: i32 = @intCast(value);
    const bits: u32 = @bitCast(signed);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn search_in_arow_and_col_wise_sorted_matrix(
    input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const n_value = values[0];
    const target = values[1];
    if (n_value < 1 or n_value > MAX_DIMENSION or target < -2_147_483_648 or target > 2_147_483_647)
        return -1;
    const n: usize = @intCast(n_value);
    if (length != 2 + n * n) return -1;

    var target_count: usize = 0;
    for (0..n) |row| {
        for (0..n) |column| {
            const index = row * n + column;
            const value = values[2 + index];
            if (value < -2_147_483_648 or value > 2_147_483_647) return -1;
            if (column > 0 and value < values[2 + index - 1]) return -1;
            if (row > 0 and value < values[2 + index - n]) return -1;
            if (value == target) {
                target_count += 1;
                if (target_count > 1) return -1;
            }
        }
    }

    var row: usize = 0;
    var column: isize = @intCast(n);
    column -= 1;
    var result_row: i64 = -1;
    var result_column: i64 = -1;
    var found: i64 = 0;
    while (row < n and column >= 0) {
        const value = values[2 + row * n + @intCast(column)];
        if (value == target) {
            result_row = @intCast(row);
            result_column = @intCast(column);
            found = 1;
            break;
        }
        if (target > value) row += 1 else column -= 1;
    }

    if (output == null or capacity < 8) return -2;
    var buffer: [8]u8 = @splat(0);
    writeI32Le(buffer[0..], 0, result_row);
    writeI32Le(buffer[0..], 4, result_column);
    for (0..8) |index| output.?[index] = buffer[index];
    return found;
}
