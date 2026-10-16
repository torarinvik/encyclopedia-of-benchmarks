/* Scalar DenseLayer update from TheAlgorithms/Python back_propagation_neural_network.py. */
#include <cmath>
#include <cstddef>
#include <cstdint>

using std::exp;
using std::int64_t;
using std::size_t;
using std::uint8_t;
using std::uint64_t;

#define INVALID_RESULT (-1)
#define SCALE 1000000.0

static int64_t quantize(double value) {
    double scaled = value * SCALE;
    return (int64_t)(scaled >= 0.0 ? scaled + 0.5 : scaled - 0.5);
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8u));
}

extern "C" int64_t back_propagation_neural_network(const int64_t *input, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (input == NULL || length != 7) return INVALID_RESULT;
    int64_t x_q = input[0], target_q = input[1], hidden_weight_q = input[2];
    int64_t hidden_bias_q = input[3], output_weight_q = input[4];
    int64_t output_bias_q = input[5], rate_q = input[6];
    if (x_q < -1000000 || x_q > 1000000 || target_q < -1000000 || target_q > 1000000 ||
        hidden_weight_q < -2000000 || hidden_weight_q > 2000000 ||
        hidden_bias_q < -2000000 || hidden_bias_q > 2000000 ||
        output_weight_q < -2000000 || output_weight_q > 2000000 ||
        output_bias_q < -2000000 || output_bias_q > 2000000 || rate_q < 1 || rate_q > 300000)
        return INVALID_RESULT;

    double x = (double)x_q / SCALE, target = (double)target_q / SCALE;
    double hidden_weight = (double)hidden_weight_q / SCALE;
    double hidden_bias = (double)hidden_bias_q / SCALE;
    double output_weight = (double)output_weight_q / SCALE;
    double output_bias = (double)output_bias_q / SCALE;
    double learning_rate = (double)rate_q / SCALE;

    double hidden_net = hidden_weight * x - hidden_bias;
    double hidden = 1.0 / (1.0 + exp(-hidden_net));
    double output_net = output_weight * hidden - output_bias;
    double prediction = 1.0 / (1.0 + exp(-output_net));
    double loss = (target - prediction) * (target - prediction);

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

    if (output == NULL || capacity < 56) return -2;
    int64_t result[7] = {quantize(loss), quantize(hidden), quantize(prediction),
        quantize(updated_hidden_weight), quantize(updated_hidden_bias),
        quantize(updated_output_weight), quantize(updated_output_bias)};
    for (size_t index = 0; index < 7; ++index) put_i64_le(output, index * 8, result[index]);
    return 56;
}
