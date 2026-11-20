const std = @import("std");

const MAX_INPUT: usize = 48;
const MAX_OUTPUT: usize = 36;
const MIN_PROBABILITY: f64 = 0.001;
const ROW_TOLERANCE: f64 = 1e-9;

fn exactInteger(value: f64, low: i64, high: i64) bool {
    return std.math.isFinite(value) and value >= @as(f64, @floatFromInt(low)) and
        value <= @as(f64, @floatFromInt(high)) and @trunc(value) == value;
}

export fn baum_welch_reestimation(input: ?[*]const f64, input_length: usize,
        output: ?[*]f64, output_capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > MAX_INPUT) return -1;
    if (!exactInteger(values[0], 2, 4) or !exactInteger(values[1], 2, 4) or !exactInteger(values[2], 1, 8)) return -1;
    const states: usize = @intFromFloat(values[0]);
    const symbols: usize = @intFromFloat(values[1]);
    const time_count: usize = @intFromFloat(values[2]);
    if (input_length != 3 + states + states * states + states * symbols + time_count) return -1;

    var initial: [4]f64 = @splat(0.0);
    var transition: [16]f64 = @splat(0.0);
    var emission: [16]f64 = @splat(0.0);
    var observations: [8]usize = @splat(0);
    var cursor: usize = 3;
    for (0..states) |i| { initial[i] = values[cursor + i]; }
    cursor += states;
    for (0..states * states) |i| { transition[i] = values[cursor + i]; }
    cursor += states * states;
    for (0..states * symbols) |i| { emission[i] = values[cursor + i]; }
    cursor += states * symbols;

    var total: f64 = 0.0;
    for (0..states) |i| {
        const value = initial[i];
        if (!std.math.isFinite(value) or value < MIN_PROBABILITY or value > 1.0) return -1;
        total += value;
    }
    if (@abs(total - 1.0) > ROW_TOLERANCE) return -1;
    for (0..states) |state| {
        total = 0.0;
        for (0..states) |j| {
            const value = transition[state * states + j];
            if (!std.math.isFinite(value) or value < MIN_PROBABILITY or value > 1.0) return -1;
            total += value;
        }
        if (@abs(total - 1.0) > ROW_TOLERANCE) return -1;
        total = 0.0;
        for (0..symbols) |symbol| {
            const value = emission[state * symbols + symbol];
            if (!std.math.isFinite(value) or value < MIN_PROBABILITY or value > 1.0) return -1;
            total += value;
        }
        if (@abs(total - 1.0) > ROW_TOLERANCE) return -1;
    }
    for (0..time_count) |time| {
        const value = values[cursor + time];
        if (!exactInteger(value, 0, @intCast(symbols - 1))) return -1;
        observations[time] = @intFromFloat(value);
    }

    var alpha: [32]f64 = @splat(0.0);
    var beta: [32]f64 = @splat(0.0);
    var gamma: [32]f64 = @splat(0.0);
    var staged: [MAX_OUTPUT]f64 = @splat(0.0);
    for (0..states) |state| alpha[state] = initial[state] * emission[state * symbols + observations[0]];
    for (1..time_count) |time| {
        for (0..states) |destination| {
            var incoming: f64 = 0.0;
            for (0..states) |source| incoming += alpha[(time - 1) * states + source] * transition[source * states + destination];
            alpha[time * states + destination] = incoming * emission[destination * symbols + observations[time]];
        }
    }
    var likelihood: f64 = 0.0;
    for (0..states) |state| likelihood += alpha[(time_count - 1) * states + state];
    for (0..states) |state| beta[(time_count - 1) * states + state] = 1.0;
    var time = time_count;
    while (time > 1) {
        time -= 1;
        for (0..states) |source| {
            var sum: f64 = 0.0;
            for (0..states) |destination| sum += transition[source * states + destination] * emission[destination * symbols + observations[time]] * beta[time * states + destination];
            beta[(time - 1) * states + source] = sum;
        }
    }
    for (0..time_count) |t| {
        for (0..states) |state| gamma[t * states + state] = alpha[t * states + state] * beta[t * states + state] / likelihood;
    }

    const output_count = states + states * states + states * symbols;
    var out: usize = 0;
    for (0..states) |state| { staged[out] = gamma[state]; out += 1; }
    if (time_count == 1) {
        for (0..states * states) |i| { staged[out] = transition[i]; out += 1; }
    } else {
        for (0..states) |source| {
            var denominator: f64 = 0.0;
            for (0..time_count - 1) |t| denominator += gamma[t * states + source];
            for (0..states) |destination| {
                var count: f64 = 0.0;
                for (0..time_count - 1) |t| count += alpha[t * states + source] * transition[source * states + destination] * emission[destination * symbols + observations[t + 1]] * beta[(t + 1) * states + destination] / likelihood;
                staged[out] = count / denominator;
                out += 1;
            }
        }
    }
    for (0..states) |state| {
        var denominator: f64 = 0.0;
        for (0..time_count) |t| denominator += gamma[t * states + state];
        for (0..symbols) |symbol| {
            var count: f64 = 0.0;
            for (0..time_count) |t| if (observations[t] == symbol) { count += gamma[t * states + state]; };
            staged[out] = count / denominator;
            out += 1;
        }
    }
    if (out != output_count) return -1;
    const out_ptr = output orelse return -2;
    if (output_capacity < output_count) return -2;
    for (0..output_count) |i| out_ptr[i] = staged[i];
    return @intCast(output_count);
}
