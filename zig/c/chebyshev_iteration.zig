const MAX_DIMENSION: usize = 8;
const MAX_MATRIX_MICRO: i64 = 1_000_000_000;
const MAX_VECTOR_MICRO: i64 = 1_000_000_000;
const MAX_SPECTRAL_MICRO: i64 = 1_000_000_000;
const MAX_ITERATIONS: i64 = 1000;

fn writeF64Le(output: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn chebyshev_iteration(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > 1 + MAX_DIMENSION * MAX_DIMENSION + 2 * MAX_DIMENSION + 4) return -1;
    if (values[0] < 1 or values[0] > MAX_DIMENSION) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + n * n + 2 * n + 4) return -1;
    const matrix_end = 1 + n * n;
    const vector_end = matrix_end + 2 * n;
    var matrix: [MAX_DIMENSION * MAX_DIMENSION]f64 = @splat(0.0);
    var b: [MAX_DIMENSION]f64 = @splat(0.0);
    var x: [MAX_DIMENSION]f64 = @splat(0.0);
    var residual: [MAX_DIMENSION]f64 = @splat(0.0);
    var direction: [MAX_DIMENSION]f64 = @splat(0.0);
    for (0..n * n) |index| {
        const value = values[1 + index];
        if (value < -MAX_MATRIX_MICRO or value > MAX_MATRIX_MICRO) return -1;
        matrix[index] = @as(f64, @floatFromInt(value)) / 1_000_000.0;
    }
    for (0..n) |index| {
        const rhs = values[matrix_end + index];
        const guess = values[matrix_end + n + index];
        if (rhs < -MAX_VECTOR_MICRO or rhs > MAX_VECTOR_MICRO
            or guess < -MAX_VECTOR_MICRO or guess > MAX_VECTOR_MICRO) return -1;
        b[index] = @as(f64, @floatFromInt(rhs)) / 1_000_000.0;
        x[index] = @as(f64, @floatFromInt(guess)) / 1_000_000.0;
    }
    const min_micro = values[vector_end];
    const max_micro = values[vector_end + 1];
    const iterations = values[vector_end + 2];
    const tolerance_micro = values[vector_end + 3];
    if (min_micro < 1 or max_micro <= min_micro or max_micro > MAX_SPECTRAL_MICRO
        or iterations < 1 or iterations > MAX_ITERATIONS
        or tolerance_micro < 1 or tolerance_micro > MAX_VECTOR_MICRO) return -1;
    const min_eigenvalue = @as(f64, @floatFromInt(min_micro)) / 1_000_000.0;
    const max_eigenvalue = @as(f64, @floatFromInt(max_micro)) / 1_000_000.0;
    const tolerance = @as(f64, @floatFromInt(tolerance_micro)) / 1_000_000.0;
    const output_bytes = n * 8;
    if (output == null or output_capacity < output_bytes) return -2;

    for (0..n) |row| {
        var product: f64 = 0.0;
        for (0..n) |column| product += matrix[row * n + column] * x[column];
        residual[row] = b[row] - product;
    }
    const d = (max_eigenvalue + min_eigenvalue) / 2.0;
    const c = (max_eigenvalue - min_eigenvalue) / 2.0;
    var alpha: f64 = 0.0;
    var alpha_previous: f64 = 0.0;
    for (0..@intCast(iterations)) |iteration| {
        var squares: f64 = 0.0;
        for (0..n) |index| squares += residual[index] * residual[index];
        if (@sqrt(squares) < tolerance) break;
        if (iteration == 0) {
            alpha = 1.0 / d;
            for (0..n) |index| direction[index] = residual[index];
        } else {
            const half_step = c * alpha_previous / 2.0;
            const beta = half_step * half_step;
            alpha = 1.0 / (d - beta / alpha_previous);
            const direction_scale = beta / alpha_previous;
            for (0..n) |index| direction[index] = residual[index] + direction_scale * direction[index];
        }
        for (0..n) |index| x[index] += alpha * direction[index];
        for (0..n) |row| {
            var product: f64 = 0.0;
            for (0..n) |column| product += matrix[row * n + column] * x[column];
            residual[row] = b[row] - product;
        }
        alpha_previous = alpha;
    }
    for (0..n) |index| writeF64Le(output, index * 8, x[index]);
    return @intCast(output_bytes);
}
