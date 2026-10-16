const SCALE: f64 = 1_000_000.0;

fn quantize(value: f64) -> i64 {
    let scaled = value * SCALE;
    if scaled >= 0.0 { (scaled + 0.5) as i64 } else { (scaled - 0.5) as i64 }
}

fn put_i64_le(output: &mut [u8], offset: usize, value: i64) {
    output[offset..offset + 8].copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn back_propagation_neural_network(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length != 7 { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    let [x_q, target_q, hidden_weight_q, hidden_bias_q,
        output_weight_q, output_bias_q, rate_q] = values else { return -1; };
    if !(-1_000_000..=1_000_000).contains(x_q)
        || !(-1_000_000..=1_000_000).contains(target_q)
        || !(-2_000_000..=2_000_000).contains(hidden_weight_q)
        || !(-2_000_000..=2_000_000).contains(hidden_bias_q)
        || !(-2_000_000..=2_000_000).contains(output_weight_q)
        || !(-2_000_000..=2_000_000).contains(output_bias_q)
        || !(1..=300_000).contains(rate_q) { return -1; }

    let x = *x_q as f64 / SCALE;
    let target = *target_q as f64 / SCALE;
    let hidden_weight = *hidden_weight_q as f64 / SCALE;
    let hidden_bias = *hidden_bias_q as f64 / SCALE;
    let output_weight = *output_weight_q as f64 / SCALE;
    let output_bias = *output_bias_q as f64 / SCALE;
    let learning_rate = *rate_q as f64 / SCALE;
    let hidden_net = hidden_weight * x - hidden_bias;
    let hidden = 1.0 / (1.0 + (-hidden_net).exp());
    let output_net = output_weight * hidden - output_bias;
    let prediction = 1.0 / (1.0 + (-output_net).exp());
    let difference = target - prediction;
    let loss = difference * difference;
    let loss_gradient = 2.0 * (prediction - target);
    let output_delta = loss_gradient * prediction * (1.0 - prediction);
    let output_weight_gradient = output_delta * hidden;
    let output_bias_gradient = -output_delta;
    let hidden_gradient = output_delta * output_weight;
    let hidden_delta = hidden_gradient * hidden * (1.0 - hidden);
    let hidden_weight_gradient = hidden_delta * x;
    let hidden_bias_gradient = -hidden_delta;
    let updated_hidden_weight = hidden_weight - learning_rate * hidden_weight_gradient;
    let updated_hidden_bias = hidden_bias - learning_rate * hidden_bias_gradient;
    let updated_output_weight = output_weight - learning_rate * output_weight_gradient;
    let updated_output_bias = output_bias - learning_rate * output_bias_gradient;

    if output.is_null() || capacity < 56 { return -2; }
    let result = [quantize(loss), quantize(hidden), quantize(prediction),
        quantize(updated_hidden_weight), quantize(updated_hidden_bias),
        quantize(updated_output_weight), quantize(updated_output_bias)];
    let output = std::slice::from_raw_parts_mut(output, 56);
    for index in 0..7 { put_i64_le(output, index * 8, result[index]); }
    56
}
