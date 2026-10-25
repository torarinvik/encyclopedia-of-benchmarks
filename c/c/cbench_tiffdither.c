/*
Copyright (c) 1988-1997 Sam Leffler
Copyright (c) 1991-1997 Silicon Graphics, Inc.

Permission to use, copy, modify, distribute, and sell this software and
its documentation for any purpose is hereby granted without fee, provided
that (i) the above copyright notices and this permission notice appear in
all copies of the software and related documentation, and (ii) the names of
Sam Leffler and Silicon Graphics may not be used in any advertising or
publicity relating to the software without the specific, prior written
permission of Sam Leffler and Silicon Graphics.

THE SOFTWARE IS PROVIDED "AS-IS" AND WITHOUT WARRANTY OF ANY KIND,
EXPRESS, IMPLIED OR OTHERWISE, INCLUDING WITHOUT LIMITATION, ANY
WARRANTY OF MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE.

IN NO EVENT SHALL SAM LEFFLER OR SILICON GRAPHICS BE LIABLE FOR
ANY SPECIAL, INCIDENTAL, INDIRECT OR CONSEQUENTIAL DAMAGES OF ANY KIND,
OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER OR NOT ADVISED OF THE POSSIBILITY OF DAMAGE, AND ON ANY THEORY OF
LIABILITY, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
OF THIS SOFTWARE.
*/

#include <stddef.h>
#include <stdint.h>

enum { MAX_WIDTH = 32, MAX_HEIGHT = 16, MAX_PIXELS = 512, MAX_OUTPUT_BYTES = 60 };

static int trunc_div(int value, int divisor)
{
    return value < 0 ? -((-value) / divisor) : value / divisor;
}

int64_t cbench_tiffdither(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 5 || length > 515) return -1;
    if (input[0] < 1 || input[0] > MAX_WIDTH ||
        input[1] < 2 || input[1] > MAX_HEIGHT ||
        input[2] < 0 || input[2] > 255) return -1;
    const size_t width = (size_t)input[0];
    const size_t height = (size_t)input[1];
    const int threshold = (int)input[2];
    const size_t pixel_count = width * height;
    if (length != 3 + pixel_count) return -1;

    int16_t work[MAX_PIXELS] = {0};
    for (size_t i = 0; i < pixel_count; ++i) {
        if (input[i + 3] < 0 || input[i + 3] > 255) return -1;
        work[i] = (int16_t)input[i + 3];
    }

    const size_t row_bytes = (width + 7) / 8;
    const size_t output_size = row_bytes * (height - 1);
    if (output == NULL || capacity < output_size) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};

    for (size_t y = 0; y + 1 < height; ++y) {
        const int last_line = y + 2 == height;
        for (size_t x = 0; x < width; ++x) {
            const size_t at = y * width + x;
            int value = work[at];
            if (value < 0) value = 0;
            else if (value > 255) value = 255;
            if (value > threshold) {
                staged[y * row_bytes + x / 8] |= (uint8_t)(0x80u >> (x % 8));
                value -= 255;
            }

            if (x + 1 < width)
                work[at + 1] = (int16_t)(work[at + 1] + trunc_div(value * 7, 16));
            if (!last_line) {
                if (x > 0)
                    work[at + width - 1] = (int16_t)(work[at + width - 1] + trunc_div(value * 3, 16));
                work[at + width] = (int16_t)(work[at + width] + trunc_div(value * 5, 16));
                if (x + 1 < width)
                    work[at + width + 1] = (int16_t)(work[at + width + 1] + trunc_div(value, 16));
            }
        }
    }

    for (size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return (int64_t)output_size;
}
