const std = @import("std");

const MAX_N: usize = 10;
const MAX_INPUT_LENGTH: usize = 13;
const MAX_ORDER: usize = 6;
const ROW_COUNT: usize = MAX_ORDER + 1;

export fn wynn_epsilon_sequence_algorithm(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT_LENGTH) return -1;
    for (0..input_length) |i| if (!std.math.isFinite(values[i])) return -1;
    const n_value = values[0];
    const k_value = values[1];
    if (@floor(n_value) != n_value or @floor(k_value) != k_value
        or n_value < 5.0 or n_value > @as(f64, @floatFromInt(MAX_N))
        or k_value < 2.0 or k_value > 3.0) return -1;
    const n: usize = @intFromFloat(n_value);
    const k: usize = @intFromFloat(k_value);
    if (n < 2 * k + 1 or input_length != n + 2) return -1;
    for (0..n) |i| {
        const sample = values[i + 2];
        const scaled = sample * 256.0;
        if (sample < -2.0 or sample > 2.0 or @floor(scaled) != scaled) return -1;
    }

    var rows = [_][MAX_N]f64{[_]f64{0.0} ** MAX_N} ** ROW_COUNT;
    var valid = [_][MAX_N]bool{[_]bool{false} ** MAX_N} ** ROW_COUNT;
    for (0..n) |i| {
        rows[0][i] = values[i + 2];
        valid[0][i] = true;
    }
    for (0..2 * k) |order| {
        const width = n - order - 1;
        for (0..width) |i| {
            var auxiliary_valid = true;
            if (order != 0) auxiliary_valid = valid[order - 1][i + 1];
            if (!valid[order][i] or !valid[order][i + 1] or !auxiliary_valid) continue;
            const denominator = rows[order][i + 1] - rows[order][i];
            if (denominator == 0.0 or !std.math.isFinite(denominator)) continue;
            const reciprocal = 1.0 / denominator;
            var auxiliary: f64 = 0.0;
            if (order != 0) auxiliary = rows[order - 1][i + 1];
            const result = auxiliary + reciprocal;
            if (!std.math.isFinite(reciprocal) or !std.math.isFinite(result)) continue;
            rows[order + 1][i] = result;
            valid[order + 1][i] = true;
        }
    }

    var needed: usize = 0;
    var order: usize = 2;
    while (order <= 2 * k) : (order += 2) needed += 2 * (n - order);
    const destination = output orelse return -2;
    if (output_capacity < needed) return -2;
    var cursor: usize = 0;
    order = 2;
    while (order <= 2 * k) : (order += 2) {
        for (0..n - order) |i| {
            destination[cursor] = if (valid[order][i]) 0.0 else 1.0;
            destination[cursor + 1] = if (valid[order][i]) rows[order][i] else 0.0;
            cursor += 2;
        }
    }
    return @intCast(needed);
}
