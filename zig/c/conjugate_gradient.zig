const max_dimension: usize = 8;
const max_entry_micro: i64 = 1_000_000_000;
const scale: f64 = 1_000_000.0;
const tolerance: f64 = 1.0e-10;
const max_iterations: usize = 1000;

fn write_f64_le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn conjugate_gradient(values: [*c]const i64, length: usize,
                             output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or values[0] < 1 or values[0] > max_dimension) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + n * n + n) return -1;
    const vector_offset = 1 + n * n;
    var matrix: [max_dimension * max_dimension]f64 = @splat(0.0);
    var rhs: [max_dimension]f64 = @splat(0.0);
    var solution: [max_dimension]f64 = @splat(0.0);
    var residual: [max_dimension]f64 = @splat(0.0);
    var direction: [max_dimension]f64 = @splat(0.0);
    var product: [max_dimension]f64 = @splat(0.0);
    for (0..n * n + n) |index| {
        if (values[index + 1] < -max_entry_micro or values[index + 1] > max_entry_micro) return -1;
    }
    for (0..n) |row| {
        const diagonal = values[1 + row * n + row];
        if (diagonal <= 0) return -1;
        var off_diagonal_sum: i64 = 0;
        for (0..n) |column| {
            const entry = values[1 + row * n + column];
            if (entry != values[1 + column * n + row]) return -1;
            if (column != row) off_diagonal_sum += if (entry < 0) -entry else entry;
            matrix[row * n + column] = @as(f64, @floatFromInt(entry)) / scale;
        }
        if (diagonal <= off_diagonal_sum) return -1;
        rhs[row] = @as(f64, @floatFromInt(values[vector_offset + row])) / scale;
        residual[row] = rhs[row];
        direction[row] = rhs[row];
    }
    const output_bytes = n * 8;
    if (output == null or output_capacity < output_bytes) return -2;
    var residual_squared: f64 = 0.0;
    for (0..n) |index| residual_squared += residual[index] * residual[index];
    for (0..max_iterations) |_| {
        if (residual_squared <= tolerance * tolerance) break;
        for (0..n) |row| {
            product[row] = 0.0;
            for (0..n) |column| product[row] += matrix[row * n + column] * direction[column];
        }
        var denominator: f64 = 0.0;
        for (0..n) |index| denominator += direction[index] * product[index];
        if (denominator <= 0.0) return -1;
        const alpha = residual_squared / denominator;
        for (0..n) |index| {
            solution[index] += alpha * direction[index];
            residual[index] -= alpha * product[index];
        }
        var next_residual_squared: f64 = 0.0;
        for (0..n) |index| next_residual_squared += residual[index] * residual[index];
        if (next_residual_squared <= tolerance * tolerance) {
            residual_squared = next_residual_squared;
            break;
        }
        const beta = next_residual_squared / residual_squared;
        for (0..n) |index| direction[index] = residual[index] + beta * direction[index];
        residual_squared = next_residual_squared;
    }
    for (0..n) |index| write_f64_le(output, index * 8, solution[index]);
    return @intCast(output_bytes);
}
