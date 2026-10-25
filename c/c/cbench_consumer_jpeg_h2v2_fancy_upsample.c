/* Independently written bounded adaptation of the IJG h2v2 fancy upsampler.
 * Based in part on the work of the Independent JPEG Group; see the package
 * README and LICENSE.txt for the retained IJG notice and documented changes. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_WIDTH = 16, MAX_HEIGHT = 8, MAX_PIXELS = 128, MAX_OUTPUT = 512 };

int64_t cbench_consumer_jpeg_h2v2_fancy_upsample(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5 || length > 131) return -1;
    if (input[0] < 3 || input[0] > MAX_WIDTH || input[1] < 1 || input[1] > MAX_HEIGHT) return -1;
    const size_t width = (size_t)input[0], height = (size_t)input[1];
    const size_t pixels = width * height;
    if (length != 2 + pixels) return -1;
    for (size_t i = 0; i < pixels; ++i) if (input[i + 2] < 0 || input[i + 2] > 255) return -1;
    const size_t output_size = 4 * pixels;
    if (output == NULL || capacity < output_size) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    size_t p = 0;
    for (size_t y = 0; y < height; ++y) {
        for (int v = 0; v < 2; ++v) {
            const size_t far_y = v == 0 ? (y == 0 ? 0 : y - 1) : (y + 1 == height ? y : y + 1);
            int sums[MAX_WIDTH];
            for (size_t x = 0; x < width; ++x)
                sums[x] = 3 * (int)input[2 + y * width + x] + (int)input[2 + far_y * width + x];
            staged[p++] = (uint8_t)((sums[0] * 4 + 8) >> 4);
            staged[p++] = (uint8_t)((sums[0] * 3 + sums[1] + 7) >> 4);
            for (size_t x = 1; x + 1 < width; ++x) {
                staged[p++] = (uint8_t)((sums[x] * 3 + sums[x - 1] + 8) >> 4);
                staged[p++] = (uint8_t)((sums[x] * 3 + sums[x + 1] + 7) >> 4);
            }
            staged[p++] = (uint8_t)((sums[width - 1] * 3 + sums[width - 2] + 8) >> 4);
            staged[p++] = (uint8_t)((sums[width - 1] * 4 + 7) >> 4);
        }
    }
    for (size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return (int64_t)output_size;
}
