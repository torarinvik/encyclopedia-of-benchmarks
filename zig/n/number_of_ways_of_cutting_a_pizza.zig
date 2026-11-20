const max_input: usize = 39;
const modulus: i64 = 1_000_000_007;

export fn number_of_ways_of_cutting_a_pizza(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const rows_value = input[0];
    const columns_value = input[1];
    const cuts_value = input[2];
    if (rows_value < 1 or rows_value > 6 or columns_value < 1 or columns_value > 6
        or cuts_value < 0 or cuts_value > 5) return -1;
    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const cuts: usize = @intCast(cuts_value);
    if (length != 3 + rows * columns) return -1;

    var cells: [36]i64 = [_]i64{0} ** 36;
    for (0..rows * columns) |index| {
        const cell = input[3 + index];
        if (cell != 0 and cell != 1) return -1;
        cells[index] = cell;
    }

    var suffix: [49]i64 = [_]i64{0} ** 49;
    for (0..rows) |row_offset| {
        const row = rows - 1 - row_offset;
        for (0..columns) |column_offset| {
            const column = columns - 1 - column_offset;
            const at = row * 7 + column;
            suffix[at] = cells[row * columns + column]
                + suffix[(row + 1) * 7 + column]
                + suffix[row * 7 + column + 1]
                - suffix[(row + 1) * 7 + column + 1];
        }
    }

    var previous: [49]i64 = [_]i64{0} ** 49;
    var current: [49]i64 = [_]i64{0} ** 49;
    for (0..rows) |row| {
        for (0..columns) |column| {
            if (suffix[row * 7 + column] > 0) previous[row * 7 + column] = 1;
        }
    }
    for (0..cuts) |_| {
        @memset(&current, 0);
        for (0..rows) |row_offset| {
            const row = rows - 1 - row_offset;
            for (0..columns) |column_offset| {
                const column = columns - 1 - column_offset;
                const origin = row * 7 + column;
                var ways: i64 = 0;
                for (row + 1..rows) |cut_row| {
                    if (suffix[origin] - suffix[cut_row * 7 + column] > 0)
                        ways += previous[cut_row * 7 + column];
                }
                for (column + 1..columns) |cut_column| {
                    if (suffix[origin] - suffix[row * 7 + cut_column] > 0)
                        ways += previous[row * 7 + cut_column];
                }
                current[origin] = @mod(ways, modulus);
            }
        }
        previous = current;
    }
    return previous[0];
}
