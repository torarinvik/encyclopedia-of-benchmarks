const std = @import("std");
const MAX_SAMPLES: usize = 8;
const MAX_FEATURES: usize = 4;
const MAX_OUTPUT: usize = 34;

fn finite(value: f64) bool {
    return std.math.isFinite(value);
}

export fn principal_component_analysis(input: ?[*]const f64, input_length: usize,
    output: ?[*]f64, capacity: usize) i64 {
    const values = input orelse return -1;
    if (input_length < 3 or input_length > 35) return -1;
    for (0..3) |i| if (!finite(values[i]) or @trunc(values[i]) != values[i]) return -1;
    if (values[0] < 2 or values[0] > 8 or values[1] < 2 or values[1] > 4) return -1;
    const samples: usize = @intFromFloat(values[0]);
    const features: usize = @intFromFloat(values[1]);
    if (values[2] < 1 or values[2] > @as(f64, @floatFromInt(features))) return -1;
    const components: usize = @intFromFloat(values[2]);
    if (input_length != 3 + samples * features) return -1;

    var means = [_]f64{0} ** MAX_FEATURES;
    var centered = [_]f64{0} ** (MAX_SAMPLES * MAX_FEATURES);
    for (0..samples) |row| {
        for (0..features) |column| {
            const value = values[3 + row * features + column];
            if (!finite(value) or @abs(value) > 100) return -1;
            means[column] += value;
            if (!finite(means[column])) return -1;
        }
    }
    for (0..features) |column| {
        means[column] /= @as(f64, @floatFromInt(samples));
        if (!finite(means[column])) return -1;
    }
    for (0..samples) |row| {
        for (0..features) |column| {
            const value = values[3 + row * features + column] - means[column];
            if (!finite(value)) return -1;
            centered[row * features + column] = value;
        }
    }

    var matrix = [_]f64{0} ** 16;
    for (0..features) |i| {
        for (i..features) |j| {
            var covariance: f64 = 0;
            for (0..samples) |row| {
                covariance += centered[row * features + i] * centered[row * features + j];
                if (!finite(covariance)) return -1;
            }
            covariance /= @as(f64, @floatFromInt(samples));
            if (!finite(covariance)) return -1;
            matrix[i * features + j] = covariance;
            matrix[j * features + i] = covariance;
        }
    }

    var deflated = matrix;
    var eigenvectors = [_]f64{0} ** 16;
    for (0..components) |component| {
        var vector = [_]f64{1} ** MAX_FEATURES;
        var converged = false;
        var iteration: usize = 0;
        while (iteration < 1000) : (iteration += 1) {
            var previous = vector;
            var next = [_]f64{0} ** MAX_FEATURES;
            for (0..features) |i| {
                for (0..features) |j| {
                    next[i] += deflated[i * features + j] * vector[j];
                    if (!finite(next[i])) return -1;
                }
            }
            var norm_squared: f64 = 0;
            for (0..features) |i| {
                norm_squared += next[i] * next[i];
                if (!finite(norm_squared)) return -1;
            }
            const norm = @sqrt(norm_squared);
            if (!finite(norm) or norm <= 1e-10) return -1;
            for (0..features) |i| {
                next[i] /= norm;
                if (!finite(next[i])) return -1;
            }
            var difference: f64 = 0;
            for (0..features) |i| {
                const change = @abs(next[i] - previous[i]);
                if (!finite(change)) return -1;
                if (change > difference) difference = change;
            }
            vector = next;
            if (difference < 1e-10) {
                converged = true;
                break;
            }
        }
        if (!converged) return -1;

        var numerator: f64 = 0;
        for (0..features) |i| {
            var row_sum: f64 = 0;
            for (0..features) |j| {
                row_sum += deflated[i * features + j] * vector[j];
                if (!finite(row_sum)) return -1;
            }
            numerator += row_sum * vector[i];
            if (!finite(numerator)) return -1;
        }
        var denominator: f64 = 0;
        for (0..features) |i| {
            denominator += vector[i] * vector[i];
            if (!finite(denominator)) return -1;
        }
        if (denominator == 0) return -1;
        const eigenvalue = numerator / denominator;
        if (!finite(eigenvalue)) return -1;
        for (0..features) |i| {
            eigenvectors[component * MAX_FEATURES + i] = vector[i];
        }
        for (0..features) |i| {
            for (0..features) |j| {
                deflated[i * features + j] -= eigenvalue * vector[i] * vector[j];
                if (!finite(deflated[i * features + j])) return -1;
            }
        }
    }

    var staged = [_]f64{0} ** MAX_OUTPUT;
    staged[0] = @floatFromInt(samples);
    staged[1] = @floatFromInt(components);
    for (0..samples) |row| {
        for (0..components) |component| {
            var score: f64 = 0;
            for (0..features) |column| {
                score += eigenvectors[component * MAX_FEATURES + column] * centered[row * features + column];
                if (!finite(score)) return -1;
            }
            staged[2 + row * components + component] = score;
        }
    }
    const output_size = 2 + samples * components;
    const out = output orelse return -2;
    if (capacity < output_size) return -2;
    @memcpy(out[0..output_size], staged[0..output_size]);
    return @intCast(output_size);
}
