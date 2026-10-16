const MAX_FEATURES: usize = 8;
const Q_SCALE: f64 = 1_000_000.0;

fn putF64(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

pub export fn logistic_regression_rust_binary_gd(
    input: [*c]const i64,
    length: usize,
    output: [*c]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 4) return -1;
    const mv = input[0];
    const dv = input[1];
    const epochs_v = input[2];
    const alpha_q = input[3];
    if (mv < 1 or mv > 32 or dv < 1 or dv > 8 or epochs_v < 0 or epochs_v > 128
        or alpha_q < 1 or alpha_q > 100000) return -1;
    const m: usize = @intCast(mv);
    const d: usize = @intCast(dv);
    const epochs: usize = @intCast(epochs_v);
    if (length != 4 + m * d + m) return -1;
    const labels_offset = 4 + m * d;
    for (0..m * d) |index| {
        const value = input[4 + index];
        if (value < -1000000 or value > 1000000) return -1;
    }
    for (0..m) |sample| {
        const label = input[labels_offset + sample];
        if (label < 0 or label > 1000000) return -1;
    }
    const required = (d + 1) * 8;
    if (output == null or capacity < required) return -2;

    var theta = [_]f64{0.0} ** (MAX_FEATURES + 1);
    var next_theta = [_]f64{0.0} ** (MAX_FEATURES + 1);
    var gradient = [_]f64{0.0} ** (MAX_FEATURES + 1);
    const alpha = @as(f64, @floatFromInt(alpha_q)) / Q_SCALE;
    for (0..epochs) |_| {
        for (0..(d + 1)) |parameter| gradient[parameter] = 0.0;
        for (0..m) |sample| {
            var score: f64 = theta[0];
            for (0..d) |feature| {
                const x = @as(f64, @floatFromInt(input[4 + sample * d + feature])) / Q_SCALE;
                score += x * theta[feature + 1];
            }
            const prediction = 1.0 / (1.0 + @exp(-score));
            const error = prediction - @as(f64, @floatFromInt(input[labels_offset + sample])) / Q_SCALE;
            gradient[0] += error;
            for (0..d) |feature| {
                const x = @as(f64, @floatFromInt(input[4 + sample * d + feature])) / Q_SCALE;
                gradient[feature + 1] += error * x;
            }
        }
        for (0..(d + 1)) |parameter| {
            next_theta[parameter] = theta[parameter] - alpha * gradient[parameter];
        }
        for (0..(d + 1)) |parameter| theta[parameter] = next_theta[parameter];
    }
    for (0..(d + 1)) |parameter| putF64(output, parameter * 8, theta[parameter]);
    return @intCast(required);
}
