#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH ((size_t)3077)
#define MAX_OUTPUT_BYTES ((size_t)3072)

int64_t resize(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;

    const int64_t src_width = input[0];
    const int64_t src_height = input[1];
    const int64_t dst_width = input[2];
    const int64_t dst_height = input[3];
    if (src_width < 1 || src_width > 32 || src_height < 1 || src_height > 32 ||
        dst_width < 1 || dst_width > 32 || dst_height < 1 || dst_height > 32) {
        return -1;
    }

    const size_t expected_length = 4 + 3 * (size_t)src_width * (size_t)src_height;
    if (length != expected_length) return -1;
    for (size_t i = 4; i < expected_length; ++i) {
        if (input[i] < 0 || input[i] > 255) return -1;
    }

    const size_t needed = 3 * (size_t)dst_width * (size_t)dst_height;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < needed) return -2;

    const double ratio_x = (double)src_width / (double)dst_width;
    const double ratio_y = (double)src_height / (double)dst_height;
    size_t out = 0;
    for (size_t y = 0; y < (size_t)dst_height; ++y) {
        const size_t src_y = (size_t)(ratio_y * (double)y);
        for (size_t x = 0; x < (size_t)dst_width; ++x) {
            const size_t src_x = (size_t)(ratio_x * (double)x);
            const size_t src = 4 + 3 * (src_y * (size_t)src_width + src_x);
            output[out++] = (uint8_t)input[src];
            output[out++] = (uint8_t)input[src + 1];
            output[out++] = (uint8_t)input[src + 2];
        }
    }
    return (int64_t)needed;
}
