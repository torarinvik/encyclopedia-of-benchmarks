/*
Copyright 1992 by Stichting Mathematisch Centrum, Amsterdam, The Netherlands.

                        All Rights Reserved

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted,
provided that the above copyright notice appear in all copies and that
both that copyright notice and this permission notice appear in
supporting documentation, and that the names of Stichting Mathematisch
Centrum or CWI not be used in advertising or publicity pertaining to
distribution of the software without specific, written prior permission.

STICHTING MATHEMATISCH CENTRUM DISCLAIMS ALL WARRANTIES WITH REGARD TO
THIS SOFTWARE, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS, IN NO EVENT SHALL STICHTING MATHEMATISCH CENTRUM BE LIABLE
FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_encode_samples = 256;
constexpr std::int64_t max_decode_bytes = 128;
constexpr int index_table[16] = {-1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8};
constexpr int step_table[89] = {
    7,8,9,10,11,12,13,14,16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,
    88,97,107,118,130,143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,
    598,658,724,796,876,963,1060,1166,1282,1411,1552,1707,1878,2066,2272,2499,2749,
    3024,3327,3660,4026,4428,4871,5358,5894,6484,7132,7845,8630,9493,10442,11487,
    12635,13899,15289,16818,18500,20350,22385,24623,27086,29794,32767
};
int clamp_index(int index) { return index < 0 ? 0 : (index > 88 ? 88 : index); }
int clamp_sample(int sample) { return sample < -32768 ? -32768 : (sample > 32767 ? 32767 : sample); }
std::uint8_t encode_one(int sample, int &predictor, int &index) {
    int step = step_table[index], diff = sample - predictor;
    const int sign = diff < 0 ? 8 : 0;
    if (sign != 0) diff = -diff;
    int code = 0, difference = step >> 3;
    if (diff >= step) { code = 4; diff -= step; difference += step; }
    step >>= 1;
    if (diff >= step) { code |= 2; diff -= step; difference += step; }
    step >>= 1;
    if (diff >= step) { code |= 1; difference += step; }
    predictor = clamp_sample(predictor + (sign ? -difference : difference));
    code |= sign;
    index = clamp_index(index + index_table[code]);
    return static_cast<std::uint8_t>(code);
}
int decode_one(std::uint8_t code, int &predictor, int &index) {
    const int step = step_table[index];
    index = clamp_index(index + index_table[code]);
    const int magnitude = code & 7;
    int difference = step >> 3;
    if (magnitude & 4) difference += step;
    if (magnitude & 2) difference += step >> 1;
    if (magnitude & 1) difference += step >> 2;
    predictor = clamp_sample(predictor + ((code & 8) ? -difference : difference));
    return predictor;
}
}

extern "C" std::int64_t lac_adpcm(const std::int64_t *input, std::size_t length,
                                   std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > static_cast<std::size_t>(max_encode_samples + 2)) return -1;
    const std::int64_t mode = input[0], count = input[1];
    if (mode == 1) {
        if (count < 0 || count > max_encode_samples || length != static_cast<std::size_t>(count) + 2) return -1;
        for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i)
            if (input[i + 2] < -32768 || input[i + 2] > 32767) return -1;
    } else if (mode == 2) {
        if (count < 0 || count > max_decode_bytes || length != static_cast<std::size_t>(count) + 2) return -1;
        for (std::size_t i = 0; i < static_cast<std::size_t>(count); ++i)
            if (input[i + 2] < 0 || input[i + 2] > 255) return -1;
    } else return -1;

    const auto n = static_cast<std::size_t>(count);
    const std::size_t required = mode == 1 ? (n + 1) / 2 : n * 4;
    if (required == 0) return 0;
    if (output == nullptr || capacity < required) return -2;
    int predictor = 0, index = 0;
    if (mode == 1) {
        for (std::size_t i = 0; i < n; ++i) {
            const auto code = encode_one(static_cast<int>(input[i + 2]), predictor, index);
            if ((i & 1u) == 0) output[i / 2] = static_cast<std::uint8_t>(code << 4);
            else output[i / 2] |= code;
        }
    } else {
        for (std::size_t i = 0; i < n; ++i) {
            const auto packed = static_cast<std::uint8_t>(input[i + 2]);
            for (std::size_t half = 0; half < 2; ++half) {
                const auto code = static_cast<std::uint8_t>(half == 0 ? packed >> 4 : packed & 15u);
                const auto sample = static_cast<std::uint16_t>(decode_one(code, predictor, index));
                const auto position = (i * 2 + half) * 2;
                output[position] = static_cast<std::uint8_t>(sample);
                output[position + 1] = static_cast<std::uint8_t>(sample >> 8);
            }
        }
    }
    return static_cast<std::int64_t>(required);
}
