/* Integer-only, four-normal Hough accumulator for an 8 by 8 binary grid. */
#include <stddef.h>
#include <stdint.h>

#define MAX_HEIGHT 8
#define MAX_WIDTH 8
#define MAX_CELLS (MAX_HEIGHT * MAX_WIDTH)
#define MAX_PARSEABLE_INPUT_LENGTH (2 + MAX_CELLS + 1)
#define ANGLE_COUNT 4
#define RHO_MIN (-14)
#define RHO_MAX 14
#define RHO_COUNT (RHO_MAX - RHO_MIN + 1)
#define OUTPUT_BYTES (ANGLE_COUNT * RHO_COUNT)

int64_t hough_line_transform(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t height_value = input[0];
    const int64_t width_value = input[1];
    if (height_value < 1 || height_value > MAX_HEIGHT ||
        width_value < 1 || width_value > MAX_WIDTH) return -1;
    const size_t height = (size_t)height_value;
    const size_t width = (size_t)width_value;
    const size_t cells = height * width;
    if (length != 2 + cells) return -1;
    for (size_t index = 0; index < cells; ++index) {
        if (input[index + 2] != 0 && input[index + 2] != 1) return -1;
    }
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;

    uint8_t accumulator[OUTPUT_BYTES] = {0};
    for (size_t row = 0; row < height; ++row) {
        for (size_t column = 0; column < width; ++column) {
            if (input[2 + row * width + column] == 0) continue;
            const int64_t x = (int64_t)column;
            const int64_t y = (int64_t)row;
            const int64_t rho[ANGLE_COUNT] = {x, x + y, y, -x + y};
            for (size_t angle = 0; angle < ANGLE_COUNT; ++angle) {
                const size_t bin = angle * RHO_COUNT + (size_t)(rho[angle] - RHO_MIN);
                ++accumulator[bin];
            }
        }
    }
    for (size_t index = 0; index < OUTPUT_BYTES; ++index) output[index] = accumulator[index];
    return OUTPUT_BYTES;
}
