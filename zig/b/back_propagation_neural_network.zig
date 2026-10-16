const scale: f64 = 1_000_000.0;

fn quantize(value: f64) i64 {
    const scaled = value * scale;
    return @intFromFloat(if (scaled >= 0.0) scaled + 0.5 else scaled - 0.5);
}

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn back_propagation_neural_network(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 7) return -1;
    const x_q = input[0];
    const target_q = input[1];
    const hidden_weight_q = input[2];
    const hidden_bias_q = input[3];
    const output_weight_q = input[4];
    const output_bias_q = input[5];
    const rate_q = input[6];
    if (x_q < -1_000_000 or x_q > 1_000_000 or target_q < -1_000_000 or target_q > 1_000_000 or
        hidden_weight_q < -2_000_000 or hidden_weight_q > 2_000_000 or
        hidden_bias_q < -2_000_000 or hidden_bias_q > 2_000_000 or
        output_weight_q < -2_000_000 or output_weight_q > 2_000_000 or
        output_bias_q < -2_000_000 or output_bias_q > 2_000_000 or rate_q < 1 or rate_q > 300_000)
        return -1;

    const x = @as(f64, @floatFromInt(x_q)) / scale;
    const target = @as(f64, @floatFromInt(target_q)) / scale;
    const hidden_weight = @as(f64, @floatFromInt(hidden_weight_q)) / scale;
    const hidden_bias = @as(f64, @floatFromInt(hidden_bias_q)) / scale;
    const output_weight = @as(f64, @floatFromInt(output_weight_q)) / scale;
    const output_bias = @as(f64, @floatFromInt(output_bias_q)) / scale;
    const learning_rate = @as(f64, @floatFromInt(rate_q)) / scale;
    const hidden_net = hidden_weight * x - hidden_bias;
    const hidden = 1.0 / (1.0 + @exp(-hidden_net));
    const output_net = output_weight * hidden - output_bias;
    const prediction = 1.0 / (1.0 + @exp(-output_net));
    const difference = target - prediction;
    const loss = difference * difference;
    const loss_gradient = 2.0 * (prediction - target);
    const output_delta = loss_gradient * prediction * (1.0 - prediction);
    const output_weight_gradient = output_delta * hidden;
    const output_bias_gradient = -output_delta;
    const hidden_gradient = output_delta * output_weight;
    const hidden_delta = hidden_gradient * hidden * (1.0 - hidden);
    const hidden_weight_gradient = hidden_delta * x;
    const hidden_bias_gradient = -hidden_delta;
    const updated_hidden_weight = hidden_weight - learning_rate * hidden_weight_gradient;
    const updated_hidden_bias = hidden_bias - learning_rate * hidden_bias_gradient;
    const updated_output_weight = output_weight - learning_rate * output_weight_gradient;
    const updated_output_bias = output_bias - learning_rate * output_bias_gradient;

    if (output == null or capacity < 56) return -2;
    const result = [_]i64{ quantize(loss), quantize(hidden), quantize(prediction),
        quantize(updated_hidden_weight), quantize(updated_hidden_bias),
        quantize(updated_output_weight), quantize(updated_output_bias) };
    for (0..7) |index| putI64Le(output, index * 8, result[index]);
    return 56;
}
