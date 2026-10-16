const Q_SCALE: f64 = 1_000_000.0;
const INVALID_RESULT: f64 = -1.0e300;

export fn logistic_regression_csharp_binary_gd(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 4) return INVALID_RESULT;
    const values = input.?[0..length];
    const mv = values[0];
    const dv = values[1];
    const epochs_v = values[2];
    const rate_q = values[3];
    if (mv < 1 or mv > 32 or dv < 1 or dv > 8 or epochs_v < 0 or epochs_v > 128
        or rate_q < 1 or rate_q > 100_000) return INVALID_RESULT;
    const m: usize = @intCast(mv);
    const d: usize = @intCast(dv);
    const epochs: usize = @intCast(epochs_v);
    const labels_offset = 4 + m * d;
    const query_offset = labels_offset + m;
    if (length != query_offset + d) return INVALID_RESULT;
    for (0..m * d) |index| {
        const value = values[4 + index];
        if (value < -1_000_000 or value > 1_000_000) return INVALID_RESULT;
    }
    for (0..m) |sample| {
        const label = values[labels_offset + sample];
        if (label != 0 and label != 1) return INVALID_RESULT;
    }
    for (0..d) |feature| {
        const value = values[query_offset + feature];
        if (value < -1_000_000 or value > 1_000_000) return INVALID_RESULT;
    }

    var weights = [_]f64{0.0} ** 8;
    var gradient = [_]f64{0.0} ** 8;
    var bias: f64 = 0.0;
    const learning_rate = @as(f64, @floatFromInt(rate_q)) / Q_SCALE;
    for (0..epochs) |_| {
        for (0..d) |feature| gradient[feature] = 0.0;
        var bias_gradient: f64 = 0.0;
        for (0..m) |sample| {
            var dot: f64 = 0.0;
            for (0..d) |feature| {
                const x = @as(f64, @floatFromInt(values[4 + sample * d + feature])) / Q_SCALE;
                dot += x * weights[feature];
            }
            const linear = dot + bias;
            const prediction = 1.0 / (1.0 + @exp(-linear));
            const error = prediction - @as(f64, @floatFromInt(values[labels_offset + sample]));
            for (0..d) |feature| {
                const x = @as(f64, @floatFromInt(values[4 + sample * d + feature])) / Q_SCALE;
                gradient[feature] += error * x;
            }
            bias_gradient += error;
        }
        for (0..d) |feature| {
            weights[feature] -= learning_rate * gradient[feature] / @as(f64, @floatFromInt(m));
        }
        bias -= learning_rate * bias_gradient / @as(f64, @floatFromInt(m));
    }
    var query_dot: f64 = 0.0;
    for (0..d) |feature| {
        const x = @as(f64, @floatFromInt(values[query_offset + feature])) / Q_SCALE;
        query_dot += x * weights[feature];
    }
    const query_linear = query_dot + bias;
    return 1.0 / (1.0 + @exp(-query_linear));
}
