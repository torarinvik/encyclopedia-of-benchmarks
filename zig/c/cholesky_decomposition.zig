const max_dimension: usize = 6;
const max_entry_micro: i64 = 1_000_000_000;

fn write_f64_le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn cholesky_decomposition(values: [*c]const i64, length: usize,
                                 output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or values[0] < 1 or values[0] > max_dimension) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + n * n) return -1;

    var matrix: [max_dimension * max_dimension]f64 = @splat(0.0);
    var lower: [max_dimension * max_dimension]f64 = @splat(0.0);
    for (0..n * n) |index| {
        const scaled = values[index + 1];
        if (scaled < -max_entry_micro or scaled > max_entry_micro) return -1;
        matrix[index] = @as(f64, @floatFromInt(scaled)) / 1_000_000.0;
    }
    for (0..n) |row| {
        for (0..n) |column| {
            const left = matrix[row * n + column];
            const right = matrix[column * n + row];
            if (@abs(left - right) > 1.0e-8 + 1.0e-5 * @abs(right)) return -1;
        }
    }

    for (0..n) |row| {
        for (0..row + 1) |column| {
            var sum: f64 = 0.0;
            for (0..column) |index| sum += lower[row * n + index] * lower[column * n + index];
            const residual = matrix[row * n + column] - sum;
            if (row == column) {
                if (residual <= 0.0) return -1;
                lower[row * n + column] = @sqrt(residual);
            } else {
                lower[row * n + column] = residual / lower[column * n + column];
            }
        }
    }

    const output_bytes = n * n * 8;
    if (output_bytes > output_capacity or output == null) return -2;
    for (0..n * n) |index| write_f64_le(output, index * 8, lower[index]);
    return @intCast(output_bytes);
}
