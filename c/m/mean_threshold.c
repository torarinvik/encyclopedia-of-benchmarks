#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 32
#define MAX_PARSEABLE_INPUT_LENGTH 1027

int64_t mean_threshold(const int64_t *input, size_t length, uint8_t *output,
                       size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_DIMENSION ||
        input[1] < 1 || input[1] > MAX_DIMENSION) return -1;

    const size_t width = (size_t)input[0];
    const size_t height = (size_t)input[1];
    const size_t pixel_count = width * height;
    if (length != pixel_count + 2) return -1;

    int64_t sum = 0;
    for (size_t i = 0; i < pixel_count; ++i) {
        const int64_t pixel = input[2 + i];
        if (pixel < 0 || pixel > 255) return -1;
        sum += pixel;
    }

    const int64_t mean = sum / (int64_t)pixel_count;
    if (output_capacity < pixel_count || output == NULL) return -2;
    for (size_t i = 0; i < pixel_count; ++i)
        output[i] = input[2 + i] > mean ? 255 : 0;
    return (int64_t)pixel_count;
}

