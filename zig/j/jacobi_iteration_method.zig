fn put(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn jacobi_iteration_method(
    values: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (values == null or length < 2 or length > 26) return -1;
    const input = values.?[0..length];
    const dimension_raw = input[0];
    const iterations = input[1];
    if (dimension_raw < 2 or dimension_raw > 4 or iterations < 1 or iterations > 8) return -1;
    const dimension: usize = @intCast(dimension_raw);
    if (length != 2 + dimension * dimension + 2 * dimension) return -1;

    const rhs_offset = 2 + dimension * dimension;
    const initial_offset = rhs_offset + dimension;
    var matrix = [_][4]f64{.{0} ** 4} ** 4;
    var rhs = [_]f64{0} ** 4;
    var current = [_]f64{0} ** 4;
    var updated = [_]f64{0} ** 4;

    for (0..dimension) |row| {
        var off_diagonal_sum: f64 = 0;
        for (0..dimension) |column| {
            const raw = input[2 + row * dimension + column];
            if (raw < 0 or raw > 4000) return -1;
            matrix[row][column] = @as(f64, @floatFromInt(raw)) / 1000.0;
            if (row != column) off_diagonal_sum += matrix[row][column];
        }
        if (matrix[row][row] <= off_diagonal_sum) return -1;

        const rhs_raw = input[rhs_offset + row];
        const initial_raw = input[initial_offset + row];
        if (rhs_raw < -2000 or rhs_raw > 2000 or initial_raw < -2000 or initial_raw > 2000) return -1;
        rhs[row] = @as(f64, @floatFromInt(rhs_raw)) / 1000.0;
        current[row] = @as(f64, @floatFromInt(initial_raw)) / 1000.0;
    }

    const output_bytes = dimension * 8;
    if (output == null or capacity < output_bytes) return -2;
    const output_pointer = output.?;

    for (0..@intCast(iterations)) |_| {
        for (0..dimension) |row| {
            var sum: f64 = 0;
            for (0..dimension) |column| {
                if (row != column) sum -= matrix[row][column] * current[column];
            }
            updated[row] = (sum + rhs[row]) / matrix[row][row];
        }
        for (0..dimension) |row| current[row] = updated[row];
    }

    for (0..dimension) |row| put(output_pointer, row * 8, current[row]);
    return @intCast(output_bytes);
}
