const std = @import("std");
const MAX_INPUT_LENGTH: usize = 56;
const MAX_MAP_SIZE: usize = 4;
const MAX_FEATURE_COUNT: usize = 3;

fn exactInteger(value: f64, minimum: f64, maximum: f64) bool {
    return std.math.isFinite(value) and @trunc(value) == value and value >= minimum and value <= maximum;
}

export fn kohonen_som_topology(input: ?[*]const f64, input_length: usize, output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 4 or input_length > MAX_INPUT_LENGTH or
        !exactInteger(values[0], 1, MAX_MAP_SIZE) or !exactInteger(values[1], 1, MAX_FEATURE_COUNT) or
        !exactInteger(values[2], 0, 8) or !exactInteger(values[3], 1, 16)) return -1;
    const map_size: usize = @intFromFloat(values[0]);
    const feature_count: usize = @intFromFloat(values[1]);
    const radius: usize = @intFromFloat(values[2]);
    const alpha_code: usize = @intFromFloat(values[3]);
    const cell_count = map_size * map_size;
    const weight_count = cell_count * feature_count;
    if (input_length != 4 + feature_count + weight_count) return -1;

    var sample = [_]f64{0} ** MAX_FEATURE_COUNT;
    for (0..feature_count) |feature| {
        if (!exactInteger(values[4 + feature], -8, 8)) return -1;
        sample[feature] = values[4 + feature];
    }
    var weights = [_]f64{0} ** 48;
    for (0..weight_count) |index| {
        const value = values[4 + feature_count + index];
        if (!exactInteger(value, -8, 8)) return -1;
        weights[index] = value;
    }

    var best_matching_unit: usize = 0;
    var best_distance_squared: f64 = 0;
    for (0..feature_count) |feature| {
        const difference = weights[feature] - sample[feature];
        best_distance_squared += difference * difference;
    }
    var best_distance = @sqrt(best_distance_squared);
    for (1..cell_count) |cell| {
        var distance_squared: f64 = 0;
        for (0..feature_count) |feature| {
            const difference = weights[cell * feature_count + feature] - sample[feature];
            distance_squared += difference * difference;
        }
        const distance = @sqrt(distance_squared);
        if (distance < best_distance) {
            best_distance = distance;
            best_matching_unit = cell;
        }
    }

    const best_x = best_matching_unit / map_size;
    const best_y = best_matching_unit % map_size;
    const first_x = best_x -| radius;
    const after_x = @min(map_size, best_x + radius + 1);
    const first_y = best_y -| radius;
    const after_y = @min(map_size, best_y + radius + 1);
    const alpha: f64 = @as(f64, @floatFromInt(alpha_code)) / 16.0;
    for (first_x..after_x) |x| {
        for (first_y..after_y) |y| {
            const dx = if (best_x > x) best_x - x else x - best_x;
            const dy = if (best_y > y) best_y - y else y - best_y;
            const grid_distance_squared = @as(f64, @floatFromInt(dx * dx + dy * dy));
            const scale = @exp(-grid_distance_squared / (2.0 * alpha * alpha));
            for (0..feature_count) |feature| {
                const index = (x * map_size + y) * feature_count + feature;
                const difference = sample[feature] - weights[index];
                weights[index] += alpha * scale * difference;
                if (!std.math.isFinite(weights[index])) return -1;
            }
        }
    }

    const output_length = 1 + weight_count;
    const out = output orelse return -2;
    if (capacity < output_length) return -2;
    out[0] = best_distance;
    for (0..weight_count) |index| out[index + 1] = weights[index];
    return @intCast(output_length);
}
