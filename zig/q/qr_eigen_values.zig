const std = @import("std");

export fn qr_eigen_values(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length != 5 or values[0] != 2) return -1;
    var matrix = [_]f64{0} ** 4;
    for (0..4) |i| {
        const value = values[i + 1];
        if (!std.math.isFinite(value) or value < -9 or value > 9 or @trunc(value) != value) return -1;
        matrix[i] = value;
    }
    if (matrix[1] != matrix[2] or matrix[1] == 0 or matrix[0] == matrix[3]) return -1;
    var last_eigenvalue: f64 = 0;
    var iterations: usize = 0;
    while (@abs(matrix[2]) > 1e-10) {
        if (iterations >= 256) return -1;
        last_eigenvalue = matrix[3];
        var shifted = matrix;
        shifted[0] -= last_eigenvalue;
        shifted[3] -= last_eigenvalue;
        var q = [_]f64{0} ** 4;
        var r = [_]f64{0} ** 4;
        for (0..2) |column| {
            var original = [_]f64{0} ** 2;
            var residual = [_]f64{0} ** 2;
            for (0..2) |row| {
                original[row] = shifted[row * 2 + column];
                residual[row] = original[row];
            }
            for (0..column) |previous| {
                var basis = [_]f64{0} ** 2;
                for (0..2) |row| basis[row] = q[row * 2 + previous];
                var denominator: f64 = 0;
                for (0..2) |row| denominator += basis[row] * basis[row];
                if (denominator == 0 or !std.math.isFinite(denominator)) return -1;
                var dot: f64 = 0;
                for (0..2) |row| dot += original[row] * basis[row];
                const scalar = dot / denominator;
                for (0..2) |row| residual[row] -= scalar * basis[row];
            }
            var norm_squared: f64 = 0;
            for (0..2) |row| norm_squared += residual[row] * residual[row];
            const norm = @sqrt(norm_squared);
            if (norm == 0 or !std.math.isFinite(norm)) return -1;
            for (0..2) |row| q[row * 2 + column] = residual[row] / norm;
            for (column..2) |target| {
                var dot: f64 = 0;
                for (0..2) |row| dot += q[row * 2 + column] * shifted[row * 2 + target];
                r[column * 2 + target] = dot;
            }
        }
        var updated = [_]f64{0} ** 4;
        for (0..2) |row| {
            for (0..2) |column| {
                for (0..2) |inner| updated[row * 2 + column] += r[row * 2 + inner] * q[inner * 2 + column];
            }
        }
        updated[0] += last_eigenvalue;
        updated[3] += last_eigenvalue;
        for (0..4) |i| {
            if (!std.math.isFinite(updated[i])) return -1;
            matrix[i] = updated[i];
        }
        iterations += 1;
    }
    const result = [_]f64{ matrix[0], last_eigenvalue };
    if (!std.math.isFinite(result[0]) or !std.math.isFinite(result[1])) return -1;
    const out = output orelse return -2;
    if (capacity < 2) return -2;
    @memcpy(out[0..2], result[0..2]);
    return 2;
}
