const MAX_STEPS: usize = 256;
const MAX_PARAMETERS: usize = 16;
const INPUT_SCALE: f64 = 1_000_000_000.0;
const OUTPUT_SCALE: f64 = 1_000_000.0;

fn adamSqrt(value: f64) f64 {
    if (value <= 0.0) return 0.0;
    var root: f64 = if (value > 1.0) value else 1.0;
    for (0..80) |_| root = 0.5 * (root + value / root);
    return root;
}

export fn adam(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    const max_input_length = 7 + MAX_PARAMETERS + MAX_STEPS * MAX_PARAMETERS;
    if (length < 9 or length > max_input_length) return -1;
    const steps_value = input[0];
    const parameter_count_value = input[1];
    const learning_rate_value = input[2];
    const beta1_value = input[3];
    const beta2_value = input[4];
    const epsilon_value = input[5];
    const weight_decay_value = input[6];
    if (steps_value < 1 or steps_value > @as(i64, @intCast(MAX_STEPS)) or
        parameter_count_value < 1 or parameter_count_value > @as(i64, @intCast(MAX_PARAMETERS))) return -1;
    const steps: usize = @intCast(steps_value);
    const parameter_count: usize = @intCast(parameter_count_value);
    if (length != 7 + parameter_count + steps * parameter_count or
        learning_rate_value < 1 or learning_rate_value > 1_000_000_000 or
        beta1_value < 0 or beta1_value >= 1_000_000_000 or beta2_value < 0 or beta2_value >= 1_000_000_000 or
        epsilon_value < 1 or epsilon_value > 10_000_000 or weight_decay_value < 0 or weight_decay_value > 100_000_000) return -1;
    for (0..parameter_count) |i| {
        if (input[7 + i] < -1_000_000_000_000_000 or input[7 + i] > 1_000_000_000_000_000) return -1;
    }
    const gradient_start = 7 + parameter_count;
    for (0..steps * parameter_count) |i| {
        if (input[gradient_start + i] < -1_000_000_000_000 or input[gradient_start + i] > 1_000_000_000_000) return -1;
    }
    const output_count = steps * parameter_count;
    if (output_capacity < 8 * output_count) return -2;

    const learning_rate = @as(f64, @floatFromInt(learning_rate_value)) / INPUT_SCALE;
    const beta1 = @as(f64, @floatFromInt(beta1_value)) / INPUT_SCALE;
    const beta2 = @as(f64, @floatFromInt(beta2_value)) / INPUT_SCALE;
    const epsilon = @as(f64, @floatFromInt(epsilon_value)) / INPUT_SCALE;
    const weight_decay = @as(f64, @floatFromInt(weight_decay_value)) / INPUT_SCALE;
    var parameters: [MAX_PARAMETERS]f64 = @splat(0.0);
    var first_moment: [MAX_PARAMETERS]f64 = @splat(0.0);
    var second_moment: [MAX_PARAMETERS]f64 = @splat(0.0);
    for (0..parameter_count) |i| parameters[i] = @as(f64, @floatFromInt(input[7 + i])) / INPUT_SCALE;
    var beta1_power: f64 = 1.0;
    var beta2_power: f64 = 1.0;
    for (0..steps) |step| {
        beta1_power *= beta1;
        beta2_power *= beta2;
        for (0..parameter_count) |i| {
            const gradient = @as(f64, @floatFromInt(input[gradient_start + step * parameter_count + i])) / INPUT_SCALE;
            first_moment[i] = beta1 * first_moment[i] + (1.0 - beta1) * gradient;
            second_moment[i] = beta2 * second_moment[i] + (1.0 - beta2) * (gradient * gradient);
            const corrected_first = first_moment[i] / (1.0 - beta1_power);
            const corrected_second = second_moment[i] / (1.0 - beta2_power);
            const updated = parameters[i] - learning_rate * corrected_first /
                (adamSqrt(corrected_second) + epsilon) - learning_rate * weight_decay * parameters[i];
            parameters[i] = updated;
            const encoded: i64 = @intFromFloat(updated * OUTPUT_SCALE);
            const bits: u64 = @bitCast(encoded);
            const output_index = step * parameter_count + i;
            for (0..8) |byte| output[8 * output_index + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
        }
    }
    return @intCast(output_count);
}
