const std = @import("std");

const MAX_N: usize = 6;
const MAX_INPUT: usize = 15;
const GRID_DENOMINATOR: f64 = 18014398509481984.0;
const MIN_NODE_SEPARATION: f64 = 0.0625;
const LOW_MAGNITUDE: f64 = 0.03125000023283064365386963;
const MAGNITUDE_CAP: f64 = 63.99999999976716935634613037;

fn gridValue(value: f64) bool {
    return std.math.isFinite(value) and value >= -8.0 and value <= 8.0 and
        @trunc(value * GRID_DENOMINATOR) == value * GRID_DENOMINATOR;
}

fn guardedMagnitude(value: f64) bool {
    return (value > LOW_MAGNITUDE and value < MAGNITUDE_CAP) or
        (value < -LOW_MAGNITUDE and value > -MAGNITUDE_CAP);
}

fn belowCap(value: f64) bool {
    return std.math.isFinite(value) and value > -MAGNITUDE_CAP and value < MAGNITUDE_CAP;
}

export fn thiele_rational_interpolation(input: ?[*]const f64, input_length: usize,
        output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 4 or input_length > MAX_INPUT) return -1;
    const n_value = values[0];
    if (!gridValue(n_value) or @trunc(n_value) != n_value or n_value < 1.0 or n_value > 6.0) return -1;
    const n: usize = @intFromFloat(n_value);
    if (input_length != 2 + 2 * n) return -1;

    var x: [MAX_N]f64 = @splat(0.0);
    var y: [MAX_N]f64 = @splat(0.0);
    var difference: [MAX_N * MAX_N]f64 = @splat(0.0);
    for (0..n) |i| {
        x[i] = values[1 + 2 * i];
        y[i] = values[2 + 2 * i];
        if (!gridValue(x[i]) or !gridValue(y[i])) return -1;
        for (0..i) |j| {
            const gap = x[i] - x[j];
            if (gap == 0.0 or @abs(gap) < MIN_NODE_SEPARATION) return -1;
        }
        difference[i] = y[i];
    }
    const query = values[input_length - 1];
    if (!gridValue(query)) return -1;

    for (1..n) |order| {
        for (order..n) |endpoint| {
            const denominator = difference[(order - 1) * MAX_N + order - 1] - difference[(order - 1) * MAX_N + endpoint];
            if (!std.math.isFinite(denominator) or !guardedMagnitude(denominator)) return -1;
            const value = (x[order - 1] - x[endpoint]) / denominator;
            if (!belowCap(value)) return -1;
            difference[order * MAX_N + endpoint] = value;
        }
        if (!guardedMagnitude(difference[order * MAX_N + order])) return -1;
    }

    var interpolated: f64 = 0.0;
    var at_node = false;
    for (0..n) |i| {
        if (query == x[i]) {
            interpolated = y[i];
            at_node = true;
            break;
        }
    }
    if (!at_node and n == 1) interpolated = y[0];
    if (!at_node and n > 1) {
        var tail = difference[(n - 1) * MAX_N + n - 1];
        var order = n - 2;
        while (order > 0) : (order -= 1) {
            if (!guardedMagnitude(tail)) return -1;
            tail = difference[order * MAX_N + order] + (query - x[order]) / tail;
            if (!belowCap(tail)) return -1;
        }
        if (!guardedMagnitude(tail)) return -1;
        interpolated = y[0] + (query - x[0]) / tail;
    }
    if (!belowCap(interpolated)) return -1;
    const out = output orelse return -2;
    if (output_capacity < 1) return -2;
    out[0] = interpolated;
    return 1;
}
