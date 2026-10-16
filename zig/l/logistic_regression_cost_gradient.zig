const MAX_FEATURES: usize = 8;
const Q_SCALE: f64 = 1_000_000.0;

fn putF64(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

pub export fn logistic_regression_cost_gradient(
    input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize,
) i64 {
    if (input == null or length < 2) return -1;
    const mv = input[0];
    const dv = input[1];
    if (mv < 1 or mv > 64 or dv < 1 or dv > MAX_FEATURES) return -1;
    const m: usize = @intCast(mv);
    const d: usize = @intCast(dv);
    const features_offset: usize = 2;
    const theta_offset = features_offset + m * d;
    const labels_offset = theta_offset + d;
    if (length != labels_offset + m) return -1;
    for (0..m * d) |index| {
        const value = input[features_offset + index];
        if (value < -1000000 or value > 1000000) return -1;
    }
    for (0..d) |feature| {
        const value = input[theta_offset + feature];
        if (value < -1000000 or value > 1000000) return -1;
    }
    for (0..m) |sample| {
        const label = input[labels_offset + sample];
        if (label != 0 and label != 1) return -1;
    }
    const required = (d + 1) * 8;
    if (output == null or capacity < required) return -2;

    var loss: f64 = 0.0;
    var gradient: [MAX_FEATURES]f64 = @splat(0.0);
    for (0..m) |sample| {
        var score: f64 = 0.0;
        for (0..d) |feature| {
            const x = @as(f64, @floatFromInt(input[features_offset + sample * d + feature])) / Q_SCALE;
            const theta = @as(f64, @floatFromInt(input[theta_offset + feature])) / Q_SCALE;
            score += x * theta;
        }
        const probability = 1.0 / (1.0 + @exp(-score));
        const label: f64 = @floatFromInt(input[labels_offset + sample]);
        loss += -label * @log(probability) - (1.0 - label) * @log(1.0 - probability);
        const residual = probability - label;
        for (0..d) |feature| {
            const x = @as(f64, @floatFromInt(input[features_offset + sample * d + feature])) / Q_SCALE;
            gradient[feature] += residual * x;
        }
    }
    putF64(output, 0, loss / @as(f64, @floatFromInt(m)));
    for (0..d) |feature| {
        putF64(output, (feature + 1) * 8, gradient[feature] / @as(f64, @floatFromInt(m)));
    }
    return @intCast(required);
}
