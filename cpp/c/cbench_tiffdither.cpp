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

#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_width = 32;
constexpr std::size_t max_height = 16;
constexpr std::size_t max_pixels = max_width * max_height;
constexpr std::size_t max_output_bytes = 60;

int trunc_div(int value, int divisor)
{
    return value < 0 ? -((-value) / divisor) : value / divisor;
}
}

extern "C" std::int64_t cbench_tiffdither(const std::int64_t *input,
                                          std::size_t length,
                                          std::uint8_t *output,
                                          std::size_t capacity)
{
    if (input == nullptr || length < 5 || length > 515) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_width) ||
        input[1] < 2 || input[1] > static_cast<std::int64_t>(max_height) ||
        input[2] < 0 || input[2] > 255) return -1;
    const auto width = static_cast<std::size_t>(input[0]);
    const auto height = static_cast<std::size_t>(input[1]);
    const int threshold = static_cast<int>(input[2]);
    const std::size_t pixel_count = width * height;
    if (length != 3 + pixel_count) return -1;

    std::int16_t work[max_pixels] = {};
    for (std::size_t i = 0; i < pixel_count; ++i) {
        if (input[i + 3] < 0 || input[i + 3] > 255) return -1;
        work[i] = static_cast<std::int16_t>(input[i + 3]);
    }

    const std::size_t row_bytes = (width + 7) / 8;
    const std::size_t output_size = row_bytes * (height - 1);
    if (output == nullptr || capacity < output_size) return -2;
    std::uint8_t staged[max_output_bytes] = {};

    for (std::size_t y = 0; y + 1 < height; ++y) {
        const bool last_line = y + 2 == height;
        for (std::size_t x = 0; x < width; ++x) {
            const std::size_t at = y * width + x;
            int value = work[at];
            if (value < 0) value = 0;
            else if (value > 255) value = 255;
            if (value > threshold) {
                staged[y * row_bytes + x / 8] |= static_cast<std::uint8_t>(0x80u >> (x % 8));
                value -= 255;
            }

            if (x + 1 < width)
                work[at + 1] = static_cast<std::int16_t>(work[at + 1] + trunc_div(value * 7, 16));
            if (!last_line) {
                if (x > 0)
                    work[at + width - 1] = static_cast<std::int16_t>(work[at + width - 1] + trunc_div(value * 3, 16));
                work[at + width] = static_cast<std::int16_t>(work[at + width] + trunc_div(value * 5, 16));
                if (x + 1 < width)
                    work[at + width + 1] = static_cast<std::int16_t>(work[at + width + 1] + trunc_div(value, 16));
            }
        }
    }

    for (std::size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(output_size);
}
