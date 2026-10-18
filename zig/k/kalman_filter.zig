const std = @import("std");

const MAX_STEPS: usize = 12;
const MAX_PARSEABLE_LENGTH: usize = 64;
const SCALE: f64 = 1_000_000.0;

export fn kalman_filter(input: [*c]const f64, length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or length < 5 or length > MAX_PARSEABLE_LENGTH) return -1;
    for (0..length) |index| {
        if (!std.math.isFinite(input[index]) or @trunc(input[index]) != input[index]) return -1;
    }
    const raw_steps = input[4];
    if (raw_steps < 1.0 or raw_steps > @as(f64, @floatFromInt(MAX_STEPS))) return -1;
    const steps: usize = @intFromFloat(raw_steps);
    if (length != 5 + steps) return -1;
    if (input[0] < -1_000_000_000.0 or input[0] > 1_000_000_000.0 or
        input[1] < 0.0 or input[1] > 1_000_000_000_000.0 or
        input[2] < 0.0 or input[2] > 1_000_000_000_000.0 or
        input[3] < 1.0 or input[3] > 1_000_000_000_000.0) return -1;
    for (0..steps) |index| {
        const measurement = input[5 + index];
        if (measurement < -1_000_000_000.0 or measurement > 1_000_000_000.0) return -1;
    }

    const required = 3 * steps;
    if (output == null or output_capacity < required) return -2;
    var estimate = input[0] / SCALE;
    var covariance = input[1] / SCALE;
    const process_noise = input[2] / SCALE;
    const measurement_noise = input[3] / SCALE;
    for (0..steps) |step| {
        const measurement = input[5 + step] / SCALE;
        estimate += 0.0;
        covariance += process_noise;
        const innovation_variance = covariance + measurement_noise;
        const gain = covariance / innovation_variance;
        estimate += gain * (measurement - estimate);
        covariance = covariance * measurement_noise / innovation_variance;
        output[3 * step] = estimate;
        output[3 * step + 1] = covariance;
        output[3 * step + 2] = gain;
    }
    return @intCast(required);
}
