const std = @import("std");

const MAX_VECTOR_LENGTH: usize = 32;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 102;

export fn rmsprop(input: [*c]const f64, input_length: usize,
    output: [*c]f64, output_capacity: usize) i64 {
    if (input == null or input_length < 5 or input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const count_value = input[0];
    if (!std.math.isFinite(count_value) or count_value < 0.0 or count_value > @as(f64, @floatFromInt(MAX_VECTOR_LENGTH))) return -1;
    const count: usize = @intFromFloat(count_value);
    if (count_value != @as(f64, @floatFromInt(count))) return -1;
    const mode_value = input[1];
    if (mode_value != 0.0 and mode_value != 1.0) return -1;
    const mode: usize = @intFromFloat(mode_value);
    if (input_length != 5 + 2 * count + (if (mode == 1) count else 0)) return -1;

    const learning_rate = input[2];
    const rho = input[3];
    const epsilon = input[4];
    if (!std.math.isFinite(learning_rate) or learning_rate < 1e-6 or learning_rate > 1.0) return -1;
    if (!std.math.isFinite(rho) or rho < 0.0 or rho > 0.99) return -1;
    if (!std.math.isFinite(epsilon) or epsilon < 1e-8 or epsilon > 1.0) return -1;

    var params = [_]f64{0.0} ** MAX_VECTOR_LENGTH;
    var gradients = [_]f64{0.0} ** MAX_VECTOR_LENGTH;
    var moving_avg = [_]f64{0.0} ** MAX_VECTOR_LENGTH;
    for (0..count) |index| {
        const param = input[5 + index];
        const gradient = input[5 + count + index];
        if (!std.math.isFinite(param) or param < -100.0 or param > 100.0) return -1;
        if (!std.math.isFinite(gradient) or gradient < -100.0 or gradient > 100.0) return -1;
        params[index] = param;
        gradients[index] = gradient;
    }
    if (mode == 1) {
        for (0..count) |index| {
            const value = input[5 + 2 * count + index];
            if (!std.math.isFinite(value) or value < 0.0 or value > 10_000.0) return -1;
            moving_avg[index] = value;
        }
    }
    if (output == null or output_capacity < 2 * count) return -2;

    for (0..count) |index| {
        const gradient = gradients[index];
        const updated_avg = rho * moving_avg[index] + (1.0 - rho) * (gradient * gradient);
        moving_avg[index] = updated_avg;
        params[index] = params[index] - (learning_rate / @sqrt(updated_avg + epsilon)) * gradient;
    }
    for (0..count) |index| {
        output[index] = params[index];
        output[count + index] = moving_avg[index];
    }
    return @intCast(2 * count);
}
