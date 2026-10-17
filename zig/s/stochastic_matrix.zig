const MAX_DIMENSION: usize = 63;
const MAX_INPUT_VALUES: usize = 3 + MAX_DIMENSION * MAX_DIMENSION;
const MAX_ABS_CELL: i64 = 1_000_000_000_000;
const CELL_SCALE: f64 = 1.0e12;
const TOLERANCE: f64 = 1.0e-9;

export fn stochastic_matrix(input: ?[*]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const mode = values[0];
    const rows_value = values[1];
    const columns_value = values[2];
    if ((mode != 0 and mode != 1) or rows_value < 1 or rows_value > MAX_DIMENSION or
        columns_value < 1 or columns_value > MAX_DIMENSION) return -1;

    const rows: usize = @intCast(rows_value);
    const columns: usize = @intCast(columns_value);
    const total = rows * columns;
    if (length != 3 + total) return -1;

    for (values[3..]) |units| {
        if (units < -MAX_ABS_CELL or units > MAX_ABS_CELL) return -1;
    }

    if (mode == 0) {
        for (0..rows) |row| {
            var sum: f64 = 0.0;
            for (0..columns) |column| {
                const value = @as(f64, @floatFromInt(values[3 + row * columns + column])) / CELL_SCALE;
                if (value < 0.0) return 0;
                sum += value;
            }
            const difference = sum - 1.0;
            if (difference > TOLERANCE or difference < -TOLERANCE) return 0;
        }
    } else {
        for (0..columns) |column| {
            var sum: f64 = 0.0;
            for (0..rows) |row| {
                const value = @as(f64, @floatFromInt(values[3 + row * columns + column])) / CELL_SCALE;
                if (value < 0.0) return 0;
                sum += value;
            }
            const difference = sum - 1.0;
            if (difference > TOLERANCE or difference < -TOLERANCE) return 0;
        }
    }
    return 1;
}
