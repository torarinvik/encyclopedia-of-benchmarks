#include <stddef.h>
#include <stdint.h>

#define GAUSSIAN_SCALE INT64_C(1000000000000000)

static int64_t gaussian_filter_weight(int64_t kernel_size, int64_t distance) {
    if (kernel_size == 3) {
        if (distance == 0) return INT64_C(159154943091895);
        if (distance == 1) return INT64_C(96532352630054);
        return INT64_C(58549831524319);
    }
    if (distance == 0) return INT64_C(198943678864869);
    if (distance == 1) return INT64_C(91083053297916);
    if (distance == 2) return INT64_C(41700860491808);
    if (distance == 4) return INT64_C(8740975213082);
    if (distance == 5) return INT64_C(4001910066968);
    return INT64_C(384051647741);
}

int64_t gaussian_filter(const int64_t *values, size_t length,
                        uint8_t *output, size_t capacity) {
    if (values == NULL || length < 3) return -1;
    int64_t height = values[0], width = values[1], kernel_size = values[2];
    if (height < 3 || height > 12 || width < 3 || width > 12
            || (kernel_size != 3 && kernel_size != 5)
            || height < kernel_size || width < kernel_size
            || length != 3 + (size_t)(height * width)) return -1;
    for (size_t index = 3; index < length; ++index)
        if (values[index] < 0 || values[index] > 255) return -1;

    size_t output_height = (size_t)(height - kernel_size + 1);
    size_t output_width = (size_t)(width - kernel_size + 1);
    size_t output_count = output_height * output_width;
    if (capacity < output_count || output == NULL) return -2;

    int64_t center = kernel_size / 2;
    for (size_t row = 0; row < output_height; ++row) {
        for (size_t column = 0; column < output_width; ++column) {
            int64_t total = 0;
            for (int64_t kernel_row = 0; kernel_row < kernel_size; ++kernel_row) {
                int64_t dy = kernel_row - center;
                for (int64_t kernel_column = 0; kernel_column < kernel_size; ++kernel_column) {
                    int64_t dx = kernel_column - center;
                    size_t pixel_index = 3 + (row + (size_t)kernel_row) * (size_t)width
                                         + column + (size_t)kernel_column;
                    total += values[pixel_index]
                             * gaussian_filter_weight(kernel_size, dx * dx + dy * dy);
                }
            }
            output[row * output_width + column] = (uint8_t)(total / GAUSSIAN_SCALE);
        }
    }
    return (int64_t)output_count;
}
