/* Flip bounded grayscale images and normalized box centers portably. */
#include <stddef.h>
#include <stdint.h>

#define MAX_WIDTH 16
#define MAX_HEIGHT 16
#define MAX_BOXES 16

static void store_i32_le(uint8_t *output, size_t position, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t flip_augmentation(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 4 || length > 340) return -1;
    if (values[0] < 1 || values[0] > MAX_WIDTH ||
        values[1] < 1 || values[1] > MAX_HEIGHT ||
        (values[2] != 0 && values[2] != 1) ||
        values[3] < 0 || values[3] > MAX_BOXES) return -1;
    const size_t width = (size_t)values[0], height = (size_t)values[1];
    const size_t flip_type = (size_t)values[2], box_count = (size_t)values[3];
    const size_t pixel_count = width * height;
    if (length != 4 + pixel_count + 5 * box_count) return -1;
    for (size_t index = 0; index < pixel_count; ++index)
        if (values[4 + index] < 0 || values[4 + index] > 255) return -1;
    for (size_t box = 0; box < box_count; ++box) {
        const size_t base = 4 + pixel_count + 5 * box;
        if (values[base] < 0 || values[base] > INT32_MAX) return -1;
        for (size_t field = 1; field < 5; ++field)
            if (values[base + field] < 0 || values[base + field] > 1000000) return -1;
    }
    const size_t output_bytes = pixel_count + 20 * box_count;
    if (output == NULL || output_capacity < output_bytes) return -2;

    for (size_t row = 0; row < height; ++row) {
        for (size_t column = 0; column < width; ++column) {
            const size_t source_row = flip_type == 0 ? height - 1 - row : row;
            const size_t source_column = flip_type == 1 ? width - 1 - column : column;
            output[row * width + column] = (uint8_t)values[4 + source_row * width + source_column];
        }
    }
    for (size_t box = 0; box < box_count; ++box) {
        const size_t base = 4 + pixel_count + 5 * box;
        const size_t output_base = pixel_count + 20 * box;
        for (size_t field = 0; field < 5; ++field) {
            int64_t value = values[base + field];
            if (flip_type == 1 && field == 1) value = 1000000 - value;
            if (flip_type == 0 && field == 2) value = 1000000 - value;
            store_i32_le(output, output_base + 4 * field, (int32_t)value);
        }
    }
    return (int64_t)output_bytes;
}
