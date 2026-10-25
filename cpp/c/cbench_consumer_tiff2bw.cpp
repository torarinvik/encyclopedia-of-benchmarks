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

extern "C" std::int64_t cbench_consumer_tiff2bw(const std::int64_t *input,
                                                std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t capacity)
{
    if (input == nullptr || length < 4 || length > 193) return -1;
    if (input[0] < 1 || input[0] > 64) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 3 * count) return -1;
    for (std::size_t i = 1; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    if (output == nullptr || capacity < count) return -2;

    for (std::size_t pixel = 0; pixel < count; ++pixel) {
        const std::size_t at = 1 + 3 * pixel;
        int value = 71 * static_cast<int>(input[at]);
        value += 150 * static_cast<int>(input[at + 1]);
        value += 28 * static_cast<int>(input[at + 2]);
        output[pixel] = static_cast<std::uint8_t>(value >> 8);
    }
    return static_cast<std::int64_t>(count);
}
