#include <stddef.h>
#include <stdint.h>
#include <math.h>

enum { MAX_SIDE = 32, MAX_PIXELS = MAX_SIDE * MAX_SIDE };

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bilateral_filter(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 5 || length > 5 + MAX_PIXELS) return -1;
    const int64_t height_value = values[0], width_value = values[1], kernel_value = values[2];
    const int64_t spatial_q = values[3], intensity_q = values[4];
    if (height_value < 1 || height_value > MAX_SIDE || width_value < 1 || width_value > MAX_SIDE ||
        (kernel_value != 1 && kernel_value != 3 && kernel_value != 5 && kernel_value != 7) ||
        spatial_q < 1 || spatial_q > 1000000 || intensity_q < 1 || intensity_q > 1000000) return -1;
    const size_t height = (size_t)height_value, width = (size_t)width_value;
    const size_t pixels = height * width;
    if (length != 5 + pixels) return -1;
    for (size_t index = 0; index < pixels; ++index)
        if (values[5 + index] < 0 || values[5 + index] > 1000000) return -1;
    const size_t required = pixels * 8;
    if (output == NULL || output_capacity < required) return -2;

    const size_t kernel_size = (size_t)kernel_value;
    const size_t radius = kernel_size / 2;
    const size_t row_end = height >= kernel_size ? height - radius : radius;
    const size_t column_end = width >= kernel_size ? width - radius : radius;
    const double spatial_variance = (double)spatial_q / 1000000.0;
    const double intensity_variance = (double)intensity_q / 1000000.0;
    int64_t filtered[MAX_PIXELS] = {0};
    for (size_t row = radius; row < row_end; ++row) {
        for (size_t column = radius; column < column_end; ++column) {
            const double center = (double)values[5 + row * width + column] / 1000000.0;
            double weighted_sum = 0.0, weight_sum = 0.0;
            for (int dy = -(int)radius; dy <= (int)radius; ++dy) {
                for (int dx = -(int)radius; dx <= (int)radius; ++dx) {
                    const size_t sample_index = (size_t)((int)row + dy) * width + (size_t)((int)column + dx);
                    const double sample = (double)values[5 + sample_index] / 1000000.0;
                    const double spatial_distance_squared = (double)(dx * dx + dy * dy);
                    const double difference = sample - center;
                    double weight = exp(-spatial_distance_squared / (2.0 * spatial_variance));
                    weight *= exp(-(difference * difference) / (2.0 * intensity_variance));
                    weighted_sum += sample * weight;
                    weight_sum += weight;
                }
            }
            filtered[row * width + column] = (int64_t)(weighted_sum / weight_sum * 1000000.0 + 0.5);
        }
    }
    for (size_t index = 0; index < pixels; ++index) write_i64_le(output, index * 8, filtered[index]);
    return (int64_t)required;
}
