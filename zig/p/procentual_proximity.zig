const MAX_ROWS: usize = 64;
const MAX_COLUMNS: usize = 8;

fn writeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    const bytes = @as(u64, @bitCast(value));
    for (0..8) |index| {
        const shift: u6 = @intCast(index * 8);
        output[offset + index] = @truncate(bytes >> shift);
    }
}

export fn procentual_proximity(input: [*c]const i64, length: usize,
                               output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 2 + MAX_COLUMNS + MAX_ROWS * MAX_COLUMNS) return -1;
    const row_value = input[0];
    const column_value = input[1];
    if (row_value < 1 or row_value > 64 or column_value < 1 or column_value > 8) return -1;
    const rows: usize = @intCast(row_value);
    const columns: usize = @intCast(column_value);
    if (length != 2 + columns + rows * columns) return -1;
    for (0..columns) |column| {
        const weight = input[2 + column];
        if (weight != 0 and weight != 1) return -1;
    }
    var data = [_][MAX_COLUMNS]f64{[_]f64{0.0} ** MAX_COLUMNS} ** MAX_ROWS;
    for (0..rows) |row| {
        for (0..columns) |column| {
            const value = input[2 + columns + row * columns + column];
            if (value < -10000 or value > 10000) return -1;
            data[row][column] = @floatFromInt(value);
        }
    }
    const output_length = rows * (columns + 1) * 8;
    if (output == null or capacity < output_length) return -2;

    var scores = [_]f64{0.0} ** MAX_ROWS;
    for (0..columns) |column| {
        var minimum = data[0][column];
        var maximum = data[0][column];
        for (1..rows) |row| {
            if (data[row][column] < minimum) minimum = data[row][column];
            if (data[row][column] > maximum) maximum = data[row][column];
        }
        const weight = input[2 + column];
        if (minimum == maximum) {
            if (weight == 0) {
                for (0..rows) |row| { scores[row] += 1.0; }
            }
        } else {
            const range = maximum - minimum;
            for (0..rows) |row| {
                var item_score = (data[row][column] - minimum) / range;
                if (weight == 0) item_score = 1.0 - item_score;
                scores[row] += item_score;
            }
        }
    }
    var offset: usize = 0;
    for (0..rows) |row| {
        for (0..columns) |column| {
            writeF64Le(output, offset, data[row][column]);
            offset += 8;
        }
        writeF64Le(output, offset, scores[row]);
        offset += 8;
    }
    return @intCast(output_length);
}
