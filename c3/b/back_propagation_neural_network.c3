module back_propagation_neural_network;

extern fn double exp(double value);
const double SCALE = 1000000.0;

fn long quantize(double value) {
    double scaled = value * SCALE;
    if (scaled >= 0.0) return (long)(scaled + 0.5);
    return (long)(scaled - 0.5);
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits >> (byte * 8));
    }
}

fn long back_propagation_neural_network_impl(long* input, usz length,
        char* output, usz capacity) {
    if (input == null || length != 7) return -1;
    long x_q = input[0];
    long target_q = input[1];
    long hidden_weight_q = input[2];
    long hidden_bias_q = input[3];
    long output_weight_q = input[4];
    long output_bias_q = input[5];
    long rate_q = input[6];
    if (x_q < -1000000 || x_q > 1000000 || target_q < -1000000 || target_q > 1000000 ||
        hidden_weight_q < -2000000 || hidden_weight_q > 2000000 ||
        hidden_bias_q < -2000000 || hidden_bias_q > 2000000 ||
        output_weight_q < -2000000 || output_weight_q > 2000000 ||
        output_bias_q < -2000000 || output_bias_q > 2000000 || rate_q < 1 || rate_q > 300000) {
        return -1;
    }
    double x = (double)x_q / SCALE;
    double target = (double)target_q / SCALE;
    double hidden_weight = (double)hidden_weight_q / SCALE;
    double hidden_bias = (double)hidden_bias_q / SCALE;
    double output_weight = (double)output_weight_q / SCALE;
    double output_bias = (double)output_bias_q / SCALE;
    double learning_rate = (double)rate_q / SCALE;

    double hidden_net = hidden_weight * x - hidden_bias;
    double hidden = 1.0 / (1.0 + exp(-hidden_net));
    double output_net = output_weight * hidden - output_bias;
    double prediction = 1.0 / (1.0 + exp(-output_net));
    double difference = target - prediction;
    double loss = difference * difference;
    double loss_gradient = 2.0 * (prediction - target);
    double output_delta = loss_gradient * prediction * (1.0 - prediction);
    double output_weight_gradient = output_delta * hidden;
    double output_bias_gradient = -output_delta;
    double hidden_gradient = output_delta * output_weight;
    double hidden_delta = hidden_gradient * hidden * (1.0 - hidden);
    double hidden_weight_gradient = hidden_delta * x;
    double hidden_bias_gradient = -hidden_delta;
    double updated_hidden_weight = hidden_weight - learning_rate * hidden_weight_gradient;
    double updated_hidden_bias = hidden_bias - learning_rate * hidden_bias_gradient;
    double updated_output_weight = output_weight - learning_rate * output_weight_gradient;
    double updated_output_bias = output_bias - learning_rate * output_bias_gradient;

    if (output == null || capacity < 56) return -2;
    long[7] result = {quantize(loss), quantize(hidden), quantize(prediction),
        quantize(updated_hidden_weight), quantize(updated_hidden_bias),
        quantize(updated_output_weight), quantize(updated_output_bias)};
    for (usz index = 0; index < 7; index++) put_i64_le(output, index * 8, result[index]);
    return 56;
}

fn long back_propagation_neural_network(long* input, usz length,
        char* output, usz capacity) @export("back_propagation_neural_network") {
    return back_propagation_neural_network_impl(input, length, output, capacity);
}
