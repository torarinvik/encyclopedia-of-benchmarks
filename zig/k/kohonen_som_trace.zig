const std = @import("std");
const MAX_INPUT_LENGTH: usize = 41;
const MAX_NODE_COUNT: usize = 8;
const MAX_FEATURE_COUNT: usize = 4;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn kohonen_som_trace(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 4 or input_length > MAX_INPUT_LENGTH or
        !exactInteger(values[0], 1, MAX_NODE_COUNT) or !exactInteger(values[1], 1, MAX_FEATURE_COUNT) or
        !exactInteger(values[2], 0, 8) or !exactInteger(values[3], 1, 16)) return -1;
    const node_count: usize = @intFromFloat(values[0]);
    const feature_count: usize = @intFromFloat(values[1]);
    const radius: usize = @intFromFloat(values[2]);
    const alpha_code: usize = @intFromFloat(values[3]);
    const weight_count = node_count * feature_count;
    if (input_length != 4 + feature_count + weight_count) return -1;

    var sample = [_]f64{0} ** MAX_FEATURE_COUNT;
    for (0..feature_count) |feature| {
        if (!exactInteger(values[4 + feature], -8, 8)) return -1;
        sample[feature] = values[4 + feature];
    }
    var weights = [_]f64{0} ** 32;
    for (0..weight_count) |index| {
        const value = values[4 + feature_count + index];
        if (!exactInteger(value, -8, 8)) return -1;
        weights[index] = value;
    }

    var best_matching_unit: usize = 0;
    var best_distance: f64 = 0;
    for (0..feature_count) |feature| {
        const difference = weights[feature] - sample[feature];
        best_distance += difference * difference;
    }
    for (1..node_count) |node| {
        var distance: f64 = 0;
        for (0..feature_count) |feature| {
            const difference = weights[node * feature_count + feature] - sample[feature];
            distance += difference * difference;
        }
        if (distance < best_distance) {
            best_distance = distance;
            best_matching_unit = node;
        }
    }

    const first_node = best_matching_unit -| radius;
    const after_last_node = @min(node_count, best_matching_unit + radius + 1);
    const alpha: f64 = @as(f64, @floatFromInt(alpha_code)) / 16.0;
    for (first_node..after_last_node) |node| {
        for (0..feature_count) |feature| {
            const index = node * feature_count + feature;
            const difference = sample[feature] - weights[index];
            weights[index] += alpha * difference;
            if (!std.math.isFinite(weights[index])) return -1;
        }
    }

    const out = output orelse return -2;
    if (capacity < weight_count) return -2;
    for (0..weight_count) |index| out[index] = weights[index];
    return @intCast(weight_count);
}
