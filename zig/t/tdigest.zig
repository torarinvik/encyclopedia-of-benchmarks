const std = @import("std");

const MIN_COMPRESSION: usize = 10;
const MAX_COMPRESSION: usize = 20;
const MAX_SAMPLES: usize = 32;
const MAX_QUERIES: usize = 4;
const MAX_INPUT_LENGTH: usize = 45;
const MAX_VALID_INPUT_LENGTH: usize = 44;
const MAX_OUTPUT_LENGTH: usize = 10;
const TWO_PI: f64 = 2.0 * std.math.pi;

fn quantileLimit(compression: f64, q: f64) f64 {
    const bounded = @min(1.0, @max(0.0, q));
    const k = compression / TWO_PI * @asin(2.0 * bounded - 1.0) + 1.0;
    const angle = k * TWO_PI / compression;
    if (angle >= std.math.pi / 2.0) return 1.0;
    if (angle <= -std.math.pi / 2.0) return 0.0;
    return (@sin(angle) + 1.0) / 2.0;
}

fn interpolate(x0: f64, y0: f64, x1: f64, y1: f64, x: f64) f64 {
    if (x1 <= x0) return y1;
    return y0 + (x - x0) / (x1 - x0) * (y1 - y0);
}

export fn tdigest(input_opt: ?[*]const f64, input_length: usize,
    output_opt: ?[*]f64, output_capacity: usize) i64 {
    const input = input_opt orelse return -1;
    if (input_length < 7 or input_length > MAX_INPUT_LENGTH) return -1;
    for (0..input_length) |index| {
        if (!std.math.isFinite(input[index])) return -1;
    }

    const compression_value = input[0];
    const sample_count_value = input[1];
    if (@trunc(compression_value) != compression_value or compression_value < 10.0 or
        compression_value > 20.0 or @trunc(sample_count_value) != sample_count_value or
        sample_count_value < 1.0 or sample_count_value > 32.0) return -1;
    const compression: usize = @intFromFloat(compression_value);
    const sample_count: usize = @intFromFloat(sample_count_value);
    const quantile_count_index = 2 + sample_count;
    if (input_length <= quantile_count_index) return -1;
    const quantile_count_value = input[quantile_count_index];
    if (@trunc(quantile_count_value) != quantile_count_value or quantile_count_value < 1.0 or
        quantile_count_value > 4.0) return -1;
    const quantile_count: usize = @intFromFloat(quantile_count_value);
    const quantile_start = quantile_count_index + 1;
    const cdf_count_index = quantile_start + quantile_count;
    if (input_length <= cdf_count_index) return -1;
    const cdf_count_value = input[cdf_count_index];
    if (@trunc(cdf_count_value) != cdf_count_value or cdf_count_value < 1.0 or cdf_count_value > 4.0) return -1;
    const cdf_count: usize = @intFromFloat(cdf_count_value);
    const cdf_start = cdf_count_index + 1;
    if (input_length != cdf_start + cdf_count or input_length > MAX_VALID_INPUT_LENGTH) return -1;

    var samples = [_]f64{0.0} ** MAX_SAMPLES;
    for (0..sample_count) |index| {
        const value = input[2 + index];
        if (value < -8.0 or value > 8.0 or @trunc(value) != value) return -1;
        samples[index] = value;
    }
    var probabilities = [_]f64{0.0} ** MAX_QUERIES;
    for (0..quantile_count) |index| {
        const value = input[quantile_start + index];
        if (value < 0.0 or value > 1.0 or @trunc(value * 4.0) != value * 4.0) return -1;
        probabilities[index] = value;
    }
    var cdf_values = [_]f64{0.0} ** MAX_QUERIES;
    for (0..cdf_count) |index| {
        const value = input[cdf_start + index];
        if (value < -8.0 or value > 8.0 or @trunc(value) != value) return -1;
        cdf_values[index] = value;
    }

    var sorted = samples;
    for (1..sample_count) |index| {
        const value = sorted[index];
        var position = index;
        while (position > 0 and sorted[position - 1] > value) : (position -= 1) {
            sorted[position] = sorted[position - 1];
        }
        sorted[position] = value;
    }

    var means = [_]f64{0.0} ** MAX_SAMPLES;
    var weights = [_]f64{0.0} ** MAX_SAMPLES;
    var centroid_count: usize = 1;
    means[0] = sorted[0];
    weights[0] = 1.0;
    var closed_weight: f64 = 0.0;
    const total_weight: f64 = @floatFromInt(sample_count);
    var weight_limit = total_weight * quantileLimit(@floatFromInt(compression), 0.0);
    const centroid_capacity = 2 * (compression + 2);
    var last: usize = 0;
    for (1..sample_count) |index| {
        const projected = weights[last] + 1.0;
        const room_left = closed_weight + projected <= weight_limit;
        if (room_left or last == centroid_capacity - 1) {
            weights[last] = projected;
            means[last] += (sorted[index] - means[last]) / projected;
        } else {
            closed_weight += weights[last];
            weight_limit = total_weight * quantileLimit(@floatFromInt(compression), closed_weight / total_weight);
            last += 1;
            means[last] = sorted[index];
            weights[last] = 1.0;
            centroid_count += 1;
        }
    }

    var staged = [_]f64{0.0} ** MAX_OUTPUT_LENGTH;
    var output_index: usize = 0;
    staged[output_index] = @floatFromInt(quantile_count);
    output_index += 1;
    const minimum = sorted[0];
    const maximum = sorted[sample_count - 1];
    for (0..quantile_count) |query| {
        const q = probabilities[query];
        var result: f64 = 0.0;
        if (centroid_count == 1) {
            result = means[0];
        } else {
            const index = q * total_weight;
            if (index <= 0.0) {
                result = minimum;
            } else if (index >= total_weight) {
                result = maximum;
            } else {
                var previous_value = minimum;
                var previous_index: f64 = 0.0;
                var current_index: f64 = 0.0;
                var found = false;
                for (0..centroid_count) |i| {
                    if (i == 0) current_index += weights[i] / 2.0 else current_index += (weights[i - 1] + weights[i]) / 2.0;
                    if (index < current_index) {
                        result = interpolate(previous_index, previous_value, current_index, means[i], index);
                        found = true;
                        break;
                    }
                    previous_value = means[i];
                    previous_index = current_index;
                }
                if (!found) result = interpolate(previous_index, previous_value, total_weight, maximum, index);
            }
        }
        staged[output_index] = result;
        output_index += 1;
    }
    staged[output_index] = @floatFromInt(cdf_count);
    output_index += 1;
    for (0..cdf_count) |query| {
        const value = cdf_values[query];
        var result: f64 = 0.0;
        if (value < minimum) {
            result = 0.0;
        } else if (value > maximum) {
            result = 1.0;
        } else if (maximum <= minimum) {
            result = 0.5;
        } else {
            var previous_value = minimum;
            var previous_index: f64 = 0.0;
            var current_index: f64 = 0.0;
            var found = false;
            for (0..centroid_count) |i| {
                if (i == 0) current_index += weights[i] / 2.0 else current_index += (weights[i - 1] + weights[i]) / 2.0;
                if (value < means[i]) {
                    result = interpolate(previous_value, previous_index, means[i], current_index, value) / total_weight;
                    found = true;
                    break;
                }
                previous_value = means[i];
                previous_index = current_index;
            }
            if (!found) result = interpolate(previous_value, previous_index, maximum, total_weight, value) / total_weight;
        }
        staged[output_index] = result;
        output_index += 1;
    }

    const output = output_opt orelse return -2;
    if (output_capacity < output_index) return -2;
    @memcpy(output[0..output_index], staged[0..output_index]);
    return @intCast(output_index);
}
