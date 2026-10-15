const MAX_SAMPLES: usize = 32;
const MAX_FEATURES: usize = 8;

fn storeI32Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn adaline_learning(input: [*]const i64, length: usize, output: [*]u8, output_capacity: usize) i64 {
    if (length < 5) return -1;
    if (input[0] < 1 or input[0] > MAX_SAMPLES or input[1] < 1 or input[1] > MAX_FEATURES or
        input[2] < 1 or input[3] < 1 or input[3] > 12 or input[4] < 1 or input[4] > 500) return -1;

    const sample_count: usize = @intCast(input[0]);
    const feature_count: usize = @intCast(input[1]);
    const eta_numerator = input[2];
    const eta_shift: u6 = @intCast(input[3]);
    const max_iterations: usize = @intCast(input[4]);
    const scale: i64 = @as(i64, 1) << eta_shift;
    if (eta_numerator >= scale or length != 5 + sample_count * (feature_count + 1)) return -1;

    for (0..sample_count) |sample| {
        const row = 5 + sample * (feature_count + 1);
        for (0..feature_count) |feature| {
            const value = input[row + feature];
            if (value < -16 or value > 16) return -1;
        }
        const label = input[row + feature_count];
        if (label != -1 and label != 1) return -1;
    }

    const byte_count = 4 * (1 + feature_count + 1 + sample_count);
    if (output_capacity < byte_count) return -2;

    var weights: [MAX_FEATURES]i64 = @splat(0);
    for (0..feature_count) |feature| weights[feature] = scale;
    var bias: i64 = scale;
    var iterations: usize = 0;
    while (iterations < max_iterations) {
        var mistakes: usize = 0;
        for (0..sample_count) |sample| {
            const row = 5 + sample * (feature_count + 1);
            var score = bias;
            for (0..feature_count) |feature| score += input[row + feature] * weights[feature];
            const prediction: i64 = if (score > 0) 1 else -1;
            const label_error = input[row + feature_count] - prediction;
            if (label_error != 0) {
                mistakes += 1;
                const correction = eta_numerator * label_error;
                for (0..feature_count) |feature| weights[feature] += correction * input[row + feature];
                bias += correction;
            }
        }
        iterations += 1;
        if (mistakes == 0) break;
    }

    var position: usize = 0;
    storeI32Le(output, position, @intCast(iterations));
    position += 4;
    for (0..feature_count) |feature| {
        storeI32Le(output, position, weights[feature]);
        position += 4;
    }
    storeI32Le(output, position, bias);
    position += 4;
    for (0..sample_count) |sample| {
        const row = 5 + sample * (feature_count + 1);
        var score = bias;
        for (0..feature_count) |feature| score += input[row + feature] * weights[feature];
        storeI32Le(output, position, if (score > 0) 1 else -1);
        position += 4;
    }
    return @intCast(byte_count);
}
