const std = @import("std");
const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 3;
const MAX_INPUT: usize = 101;

export fn mini_batch_gradient_descent(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 5 or input_length > MAX_INPUT) return -1;
    for (0..4) |i| {
        if (!std.math.isFinite(values[i]) or @trunc(values[i]) != values[i]) return -1;
    }
    if (values[0] < 1 or values[0] > 8 or values[1] < 1 or values[1] > 3) return -1;
    const samples: usize = @intFromFloat(values[0]);
    const features: usize = @intFromFloat(values[1]);
    if (values[2] < 1 or values[2] > @as(f64, @floatFromInt(samples)) or values[3] < 0 or values[3] > 8) return -1;
    const batch_size: usize = @intFromFloat(values[2]);
    const epochs: usize = @intFromFloat(values[3]);
    const learning_rate = values[4];
    if (!std.math.isFinite(learning_rate) or learning_rate < 0 or learning_rate > 0.25) return -1;
    const matrix_start: usize = 5;
    const targets_start = matrix_start + samples * features;
    const permutations_start = targets_start + samples;
    if (input_length != permutations_start + epochs * samples) return -1;

    var matrix = [_]f64{0} ** (MAX_SAMPLES * MAX_FEATURES);
    var targets = [_]f64{0} ** MAX_SAMPLES;
    for (0..samples * features) |i| {
        const value = values[matrix_start + i];
        if (!std.math.isFinite(value) or @abs(value) > 10) return -1;
        matrix[i] = value;
    }
    for (0..samples) |i| {
        const value = values[targets_start + i];
        if (!std.math.isFinite(value) or @abs(value) > 100) return -1;
        targets[i] = value;
    }
    var permutations = [_]usize{0} ** (MAX_SAMPLES * MAX_SAMPLES);
    for (0..epochs) |epoch| {
        var seen = [_]bool{false} ** MAX_SAMPLES;
        for (0..samples) |position| {
            const raw = values[permutations_start + epoch * samples + position];
            if (!std.math.isFinite(raw) or @trunc(raw) != raw or raw < 0 or raw >= @as(f64, @floatFromInt(samples))) return -1;
            const sample: usize = @intFromFloat(raw);
            if (seen[sample]) return -1;
            seen[sample] = true;
            permutations[epoch * samples + position] = sample;
        }
    }

    var weights = [_]f64{0} ** MAX_FEATURES;
    var bias: f64 = 0;
    for (0..epochs) |epoch| {
        var start: usize = 0;
        while (start < samples) {
            const remaining = samples - start;
            const batch_length = if (remaining < batch_size) remaining else batch_size;
            var errors = [_]f64{0} ** MAX_SAMPLES;
            for (0..batch_length) |position| {
                const sample = permutations[epoch * samples + start + position];
                var prediction: f64 = 0;
                for (0..features) |feature| {
                    prediction += matrix[sample * features + feature] * weights[feature];
                    if (!std.math.isFinite(prediction)) return -1;
                }
                prediction += bias;
                const error = prediction - targets[sample];
                if (!std.math.isFinite(prediction) or !std.math.isFinite(error)) return -1;
                errors[position] = error;
            }
            for (0..features) |feature| {
                var gradient: f64 = 0;
                for (0..batch_length) |position| {
                    const sample = permutations[epoch * samples + start + position];
                    gradient += matrix[sample * features + feature] * errors[position];
                    if (!std.math.isFinite(gradient)) return -1;
                }
                const update = (learning_rate * gradient) / @as(f64, @floatFromInt(batch_length));
                weights[feature] -= update;
                if (!std.math.isFinite(update) or !std.math.isFinite(weights[feature])) return -1;
            }
            var error_sum: f64 = 0;
            for (0..batch_length) |position| {
                error_sum += errors[position];
                if (!std.math.isFinite(error_sum)) return -1;
            }
            const mean_error = error_sum / @as(f64, @floatFromInt(batch_length));
            const bias_update = learning_rate * mean_error;
            bias -= bias_update;
            if (!std.math.isFinite(mean_error) or !std.math.isFinite(bias_update) or !std.math.isFinite(bias)) return -1;
            start += batch_length;
        }
    }
    var staged = [_]f64{0} ** (MAX_FEATURES + 1);
    for (0..features) |feature| staged[feature] = weights[feature];
    staged[features] = bias;
    const output_size = features + 1;
    const out = output orelse return -2;
    if (capacity < output_size) return -2;
    @memcpy(out[0..output_size], staged[0..output_size]);
    return @intCast(output_size);
}
