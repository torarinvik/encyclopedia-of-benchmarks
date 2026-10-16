const MAX_INPUT_LENGTH: usize = 31;
const MAX_OUTPUT_BYTES: usize = 48;
const I64_LIMIT: f64 = 9_223_372_036_854_775_808.0;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn finiteValue(value: f64) bool {
    return value == value and value < 1.7976931348623157e308 and value > -1.7976931348623157e308;
}

export fn simultaneous_linear_equation_solver(
    input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const n_value = values[0];
    if (n_value < 1 or n_value > 5) return -1;
    const n: usize = @intCast(n_value);
    if (length != 1 + n * (n + 1)) return -1;

    var matrix: [30]f64 = @splat(0.0);
    var has_zero = false;
    for (0..n) |row| {
        for (0..(n + 1)) |col| {
            const raw = values[1 + row * (n + 1) + col];
            if (raw < -100_000 or raw > 100_000) return -1;
            matrix[row * 6 + col] = @as(f64, @floatFromInt(raw)) / 1_000.0;
            has_zero = has_zero or raw == 0;
        }
    }

    if (n == 1) {
        if (matrix[0] == 0.0) return -1;
    } else {
        if (has_zero) {
            var full_row = n;
            for (0..n) |row| {
                var all_nonzero = true;
                for (0..(n + 1)) |col| {
                    if (matrix[row * 6 + col] == 0.0) all_nonzero = false;
                }
                if (all_nonzero) {
                    full_row = row;
                    break;
                }
            }
            if (full_row == n) return -1;
            if (full_row != 0) {
                for (0..(n + 1)) |col| {
                    const saved = matrix[full_row * 6 + col];
                    var row = full_row;
                    while (row > 0) {
                        matrix[row * 6 + col] = matrix[(row - 1) * 6 + col];
                        row -= 1;
                    }
                    matrix[col] = saved;
                }
            }
        }

        var level: usize = 0;
        while (level + 2 <= n) : (level += 1) {
            if (matrix[level * 6 + level] == 0.0) return -1;
            for (level..n) |row| {
                const magnitude = matrix[row * 6 + level];
                if (magnitude != 0.0) {
                    for (level..(n + 1)) |col| matrix[row * 6 + col] /= magnitude;
                }
            }
            var first_row: [6]f64 = @splat(0.0);
            for (level..(n + 1)) |col| first_row[col] = matrix[level * 6 + col];
            for (level + 1..n) |row| {
                if (matrix[row * 6 + level] != 0.0) {
                    for (level..(n + 1)) |col| {
                        matrix[row * 6 + col] = first_row[col] - matrix[row * 6 + col];
                    }
                }
            }
        }
    }

    for (0..n) |row| {
        for (row..(n + 1)) |col| {
            if (!finiteValue(matrix[row * 6 + col])) return -1;
        }
    }
    var solutions: [5]f64 = @splat(0.0);
    var row = n;
    while (row > 0) {
        row -= 1;
        if (matrix[row * 6 + row] == 0.0) return -1;
        var value = matrix[row * 6 + n];
        for (row + 1..n) |col| value -= matrix[row * 6 + col] * solutions[col];
        value /= matrix[row * 6 + row];
        if (!finiteValue(value)) return -1;
        solutions[row] = value;
    }

    var buffer: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    writeI64Le(buffer[0..], 0, n_value);
    for (0..n) |index| {
        const scaled = solutions[index] * 100_000.0;
        if (!finiteValue(scaled) or scaled < -I64_LIMIT or scaled >= I64_LIMIT) return -1;
        const lower = @floor(scaled);
        const midpoint = lower + 0.5;
        const exact_side = @mulAdd(f64, solutions[index], 100_000.0, -midpoint);
        if (!finiteValue(exact_side)) return -1;
        var rounded: i64 = @intFromFloat(lower);
        if (exact_side > 0.0 or (exact_side == 0.0 and @mod(rounded, 2) != 0)) rounded += 1;
        writeI64Le(buffer[0..], 8 + index * 8, rounded);
    }

    const needed = 8 + 8 * n;
    if (output == null or capacity < needed) return -2;
    for (0..needed) |index| output.?[index] = buffer[index];
    return @intCast(needed);
}
