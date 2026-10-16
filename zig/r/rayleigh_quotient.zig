const std = @import("std");

export fn rayleigh_quotient(values: [*c]const f64, length: usize,
    output: [*c]f64, capacity: usize) i64 {
    if (values == null or length == 0 or length > 273) return -1;
    for (0..length) |i| {
        if (!std.math.isFinite(values[i])) return -1;
    }
    const n_value = values[0];
    if (n_value < 1.0 or n_value > 16.0 or @floor(n_value) != n_value) return -1;
    const n: usize = @intFromFloat(n_value);
    if (length != 1 + n * n + n) return -1;
    const matrix_start = 1;
    const vector_start = 1 + n * n;

    for (0..n) |row| {
        for (0..n) |col| {
            const value = values[matrix_start + row * n + col];
            if (value < -1000.0 or value > 1000.0) return -1;
            if (col > row and value != values[matrix_start + col * n + row]) return -1;
        }
    }

    var denominator: f64 = 0.0;
    for (0..n) |i| {
        const value = values[vector_start + i];
        if (value < -100.0 or value > 100.0) return -1;
        denominator += value * value;
    }
    if (denominator <= 0.0) return -1;

    var numerator: f64 = 0.0;
    for (0..n) |col| {
        var v_star_dot: f64 = 0.0;
        for (0..n) |row| {
            v_star_dot += values[vector_start + row] * values[matrix_start + row * n + col];
        }
        numerator += v_star_dot * values[vector_start + col];
    }
    const quotient = numerator / denominator;
    if (output == null or capacity < 1) return -2;
    output[0] = quotient;
    return 1;
}
