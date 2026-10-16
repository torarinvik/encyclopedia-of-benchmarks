#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_IMAGE_SIDE 8
#define MAX_KERNEL_SIDE 4
#define MAX_FILTERS 3
#define MAX_HIDDEN 8
#define MAX_OUTPUTS 4
#define MAX_INPUT_LENGTH 2048
#define MAX_ENTRY_MICRO 1000000LL
#define MAX_IMAGE_PIXELS 64
#define MAX_KERNEL_VALUES 48
#define MAX_FEATURES 192
#define MAX_HIDDEN_WEIGHTS 1536
#define MAX_OUTPUT_WEIGHTS 32

static double sigmoid(double value) { return 1.0 / (1.0 + exp(-value)); }

static double round_three(double value) {
    const double scaled = value * 1000.0;
    const double lower = floor(scaled);
    int64_t integer = (int64_t)lower;
    const double fraction = scaled - lower;
    if (fraction > 0.5 || (fraction == 0.5 && integer % 2 != 0)) ++integer;
    return (double)integer / 1000.0;
}

static void write_f64_le(uint8_t *output, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t convolution_neural_network(const int64_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 7 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t image_side_value = values[0], kernel_side_value = values[1];
    const int64_t stride_value = values[2], filters_value = values[3];
    const int64_t pool_value = values[4], hidden_value = values[5], outputs_value = values[6];
    if (image_side_value < 2 || image_side_value > MAX_IMAGE_SIDE ||
        kernel_side_value < 1 || kernel_side_value > MAX_KERNEL_SIDE ||
        stride_value < 1 || stride_value > 4 || filters_value < 1 || filters_value > MAX_FILTERS ||
        pool_value < 1 || pool_value > 2 || hidden_value < 1 || hidden_value > MAX_HIDDEN ||
        outputs_value < 1 || outputs_value > MAX_OUTPUTS || kernel_side_value > image_side_value) return -1;
    const size_t image_side = (size_t)image_side_value, kernel_side = (size_t)kernel_side_value;
    const size_t stride = (size_t)stride_value, filters = (size_t)filters_value;
    const size_t pool_side = (size_t)pool_value, hidden = (size_t)hidden_value;
    const size_t outputs = (size_t)outputs_value;
    const size_t conv_side = (image_side - kernel_side) / stride + 1;
    if (conv_side < pool_side || conv_side % pool_side != 0) return -1;
    const size_t pooled_side = conv_side / pool_side;
    const size_t feature_count = filters * pooled_side * pooled_side;
    const size_t image_count = image_side * image_side;
    const size_t kernel_values = filters * kernel_side * kernel_side;
    const size_t hidden_weight_count = hidden * feature_count;
    const size_t output_weight_count = outputs * hidden;
    const size_t expected_length = 7 + image_count + kernel_values + filters + hidden_weight_count + output_weight_count + hidden + outputs;
    if (length != expected_length || feature_count > MAX_FEATURES) return -1;

    double image[MAX_IMAGE_PIXELS] = {0};
    double kernels[MAX_KERNEL_VALUES] = {0};
    double conv_bias[MAX_FILTERS] = {0};
    double hidden_weights[MAX_HIDDEN_WEIGHTS] = {0};
    double output_weights[MAX_OUTPUT_WEIGHTS] = {0};
    double hidden_bias[MAX_HIDDEN] = {0};
    double output_bias[MAX_OUTPUTS] = {0};
    double feature_maps[MAX_FILTERS * MAX_IMAGE_PIXELS] = {0};
    double flattened[MAX_FEATURES] = {0};
    double hidden_output[MAX_HIDDEN] = {0};
    double result[MAX_OUTPUTS] = {0};
    size_t position = 7;
    for (size_t index = 0; index < image_count; ++index) {
        const int64_t raw = values[position++];
        if (raw < 0 || raw > MAX_ENTRY_MICRO) return -1;
        image[index] = (double)raw / 1000000.0;
    }
    for (size_t index = 0; index < kernel_values; ++index) {
        const int64_t raw = values[position++];
        if (raw < -500000 || raw > 500000) return -1;
        kernels[index] = (double)raw / 1000000.0;
    }
    for (size_t index = 0; index < filters; ++index) {
        const int64_t raw = values[position++];
        if (raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO) return -1;
        conv_bias[index] = (double)raw / 1000000.0;
    }
    for (size_t index = 0; index < hidden_weight_count; ++index) {
        const int64_t raw = values[position++];
        if (raw < -500000 || raw > 500000) return -1;
        hidden_weights[index] = (double)raw / 1000000.0;
    }
    for (size_t index = 0; index < output_weight_count; ++index) {
        const int64_t raw = values[position++];
        if (raw < -500000 || raw > 500000) return -1;
        output_weights[index] = (double)raw / 1000000.0;
    }
    for (size_t index = 0; index < hidden; ++index) {
        const int64_t raw = values[position++];
        if (raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO) return -1;
        hidden_bias[index] = (double)raw / 1000000.0;
    }
    for (size_t index = 0; index < outputs; ++index) {
        const int64_t raw = values[position++];
        if (raw < -MAX_ENTRY_MICRO || raw > MAX_ENTRY_MICRO) return -1;
        output_bias[index] = (double)raw / 1000000.0;
    }
    const size_t output_bytes = outputs * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    for (size_t filter = 0; filter < filters; ++filter) {
        for (size_t top = 0; top < conv_side; ++top) {
            for (size_t left = 0; left < conv_side; ++left) {
                double total = 0.0;
                for (size_t row = 0; row < kernel_side; ++row)
                    for (size_t column = 0; column < kernel_side; ++column)
                        total += image[(top * stride + row) * image_side + left * stride + column] *
                                 kernels[filter * kernel_side * kernel_side + row * kernel_side + column];
                feature_maps[(filter * conv_side + top) * conv_side + left] = sigmoid(total - conv_bias[filter]);
            }
        }
    }
    size_t feature_index = 0;
    const size_t pool_area = pool_side * pool_side;
    for (size_t filter = 0; filter < filters; ++filter)
        for (size_t top = 0; top < conv_side; top += pool_side)
            for (size_t left = 0; left < conv_side; left += pool_side) {
                double total = 0.0;
                for (size_t row = 0; row < pool_side; ++row)
                    for (size_t column = 0; column < pool_side; ++column)
                        total += feature_maps[(filter * conv_side + top + row) * conv_side + left + column];
                flattened[feature_index++] = total / (double)pool_area;
            }
    for (size_t unit = 0; unit < hidden; ++unit) {
        double total = 0.0;
        for (size_t index = 0; index < feature_count; ++index)
            total += flattened[index] * hidden_weights[unit * feature_count + index];
        hidden_output[unit] = sigmoid(total - hidden_bias[unit]);
    }
    for (size_t unit = 0; unit < outputs; ++unit) {
        double total = 0.0;
        for (size_t index = 0; index < hidden; ++index)
            total += hidden_output[index] * output_weights[unit * hidden + index];
        result[unit] = round_three(sigmoid(total - output_bias[unit]));
        write_f64_le(output, unit * 8, result[unit]);
    }
    return (int64_t)output_bytes;
}
