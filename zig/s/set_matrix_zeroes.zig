const MAX_INPUT_LENGTH: usize = 67;
const MAX_CELLS: usize = 64;
const MIN_CELL: i64 = -1_000_000;
const MAX_CELL: i64 = 1_000_000;

fn writeI64Le(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> (8 * byte));
}

export fn set_matrix_zeroes(input: ?[*]const i64, length: usize,
                            output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const rows_value = values[0];
    const columns_value = values[1];
    if (rows_value < 1 or rows_value > 8 or columns_value < 1 or columns_value > 8) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cells = rows * columns;
    if (length != 2 + cells) return -1;

    var matrix = [_]i64{0} ** MAX_CELLS;
    for (0..cells) |index| {
        const value = values[2 + index];
        if (value < MIN_CELL or value > MAX_CELL) return -1;
        matrix[index] = value;
    }

    const bytes = cells * 8;
    if (output == null or capacity < bytes) return -2;

    var first_column_zero = false;
    for (0..rows) |row| {
        if (matrix[row * columns] == 0) first_column_zero = true;
        for (1..columns) |column| {
            if (matrix[row * columns + column] == 0) {
                matrix[row * columns] = 0;
                matrix[column] = 0;
            }
        }
    }
    for (1..rows) |row| {
        for (1..columns) |column| {
            if (matrix[row * columns] == 0 or matrix[column] == 0)
                matrix[row * columns + column] = 0;
        }
    }
    if (matrix[0] == 0) {
        for (0..columns) |column| matrix[column] = 0;
    }
    if (first_column_zero) {
        for (0..rows) |row| matrix[row * columns] = 0;
    }

    const destination = output.?;
    for (0..cells) |index| writeI64Le(destination, index * 8, matrix[index]);
    return @intCast(bytes);
}
