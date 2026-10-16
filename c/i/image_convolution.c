#include <stddef.h>
#include <stdint.h>

#define MAX_SIDE 16
#define MAX_KERNEL_SIDE 7

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t image_convolution(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 3 || length > 308) return -1;
    const int64_t side_value = values[0];
    const int64_t kernel_side_value = values[1];
    if (side_value < 1 || side_value > MAX_SIDE || kernel_side_value < 1 ||
        kernel_side_value > MAX_KERNEL_SIDE || kernel_side_value % 2 == 0) return -1;
    const size_t side = (size_t)side_value;
    const size_t kernel_side = (size_t)kernel_side_value;
    const size_t pixel_count = side * side;
    const size_t kernel_count = kernel_side * kernel_side;
    if (length != 2 + pixel_count + kernel_count) return -1;
    for (size_t index = 0; index < pixel_count; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 255) return -1;
    for (size_t index = 0; index < kernel_count; ++index)
        if (values[2 + pixel_count + index] < -16 || values[2 + pixel_count + index] > 16) return -1;
    const size_t output_bytes = pixel_count * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;

    const int64_t radius = (int64_t)(kernel_side / 2);
    for (size_t row = 0; row < side; ++row) {
        for (size_t column = 0; column < side; ++column) {
            int64_t total = 0;
            for (size_t kernel_row = 0; kernel_row < kernel_side; ++kernel_row) {
                int64_t source_row = (int64_t)row + (int64_t)kernel_row - radius;
                if (source_row < 0) source_row = 0;
                if (source_row >= (int64_t)side) source_row = (int64_t)side - 1;
                for (size_t kernel_column = 0; kernel_column < kernel_side; ++kernel_column) {
                    int64_t source_column = (int64_t)column + (int64_t)kernel_column - radius;
                    if (source_column < 0) source_column = 0;
                    if (source_column >= (int64_t)side) source_column = (int64_t)side - 1;
                    const int64_t pixel = values[2 + (size_t)source_row * side + (size_t)source_column];
                    const int64_t weight = values[2 + pixel_count + kernel_row * kernel_side + kernel_column];
                    total += pixel * weight;
                }
            }
            store_i64_le(output, (row * side + column) * 8, total);
        }
    }
    return (int64_t)output_bytes;
}
