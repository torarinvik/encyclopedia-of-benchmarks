const MAX_STEPS: usize = 256;
const MAX_GROUPS: usize = 16;
const INPUT_SCALE: f64 = 1_000_000_000.0;
const OUTPUT_SCALE: f64 = 1_000_000.0;

fn adagradSqrt(value: f64) f64 {
    if (value <= 0.0) return 0.0;
    var root: f64 = if (value > 1.0) value else 1.0;
    for (0..80) |_| root = 0.5 * (root + value / root);
    return root;
}

export fn adagrad(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 6 or length > 3 + 3 * MAX_STEPS) return -1;
    const steps_value = input[0];
    const learning_rate_value = input[1];
    const epsilon_value = input[2];
    if (steps_value < 1 or steps_value > @as(i64, @intCast(MAX_STEPS)) or length != 3 + 3 * @as(usize, @intCast(steps_value)) or
        learning_rate_value < 1 or learning_rate_value > 1_000_000_000 or
        epsilon_value < 1 or epsilon_value > 10_000_000) return -1;
    const steps: usize = @intCast(steps_value);
    for (0..steps) |step| {
        const id = input[3 + 3 * step];
        const parameter = input[4 + 3 * step];
        const gradient = input[5 + 3 * step];
        if (id < 0 or id >= @as(i64, @intCast(MAX_GROUPS)) or parameter < -1_000_000_000_000_000 or
            parameter > 1_000_000_000_000_000 or gradient < -1_000_000_000_000 or
            gradient > 1_000_000_000_000) return -1;
    }
    if (output_capacity < 8 * steps) return -2;

    const learning_rate = @as(f64, @floatFromInt(learning_rate_value)) / INPUT_SCALE;
    const epsilon = @as(f64, @floatFromInt(epsilon_value)) / INPUT_SCALE;
    var accumulated: [MAX_GROUPS]f64 = @splat(0.0);
    for (0..steps) |step| {
        const id: usize = @intCast(input[3 + 3 * step]);
        const parameter = @as(f64, @floatFromInt(input[4 + 3 * step])) / INPUT_SCALE;
        const gradient = @as(f64, @floatFromInt(input[5 + 3 * step])) / INPUT_SCALE;
        accumulated[id] += gradient * gradient;
        const updated = parameter - learning_rate / (adagradSqrt(accumulated[id]) + epsilon) * gradient;
        const encoded = @as(i64, @intFromFloat(updated * OUTPUT_SCALE));
        const bits: u64 = @bitCast(encoded);
        for (0..8) |byte| output[8 * step + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
    }
    return @intCast(steps);
}
