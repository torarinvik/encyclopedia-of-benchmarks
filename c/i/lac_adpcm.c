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

#include <stddef.h>
#include <stdint.h>

enum { MAX_ENCODE_SAMPLES = 256, MAX_DECODE_BYTES = 128 };

static const int8_t INDEX_TABLE[16] = {
    -1, -1, -1, -1, 2, 4, 6, 8, -1, -1, -1, -1, 2, 4, 6, 8
};

static const int16_t STEP_TABLE[89] = {
    7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31,
    34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88, 97, 107, 118, 130,
    143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449,
    494, 544, 598, 658, 724, 796, 876, 963, 1060, 1166, 1282, 1411,
    1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660, 4026,
    4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487,
    12635, 13899, 15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794,
    32767
};

static int32_t clamp_index(int32_t index) {
    if (index < 0) return 0;
    if (index > 88) return 88;
    return index;
}

static int32_t clamp_sample(int32_t sample) {
    if (sample > 32767) return 32767;
    if (sample < -32768) return -32768;
    return sample;
}

static uint8_t encode_sample(int32_t sample, int32_t *predictor, int32_t *index) {
    int32_t step = STEP_TABLE[*index];
    int32_t diff = sample - *predictor;
    const int32_t sign = diff < 0 ? 8 : 0;
    if (sign != 0) diff = -diff;
    int32_t delta = 0;
    int32_t difference = step >> 3;
    if (diff >= step) { delta = 4; diff -= step; difference += step; }
    step >>= 1;
    if (diff >= step) { delta |= 2; diff -= step; difference += step; }
    step >>= 1;
    if (diff >= step) { delta |= 1; difference += step; }
    *predictor = clamp_sample(*predictor + (sign != 0 ? -difference : difference));
    delta |= sign;
    *index = clamp_index(*index + INDEX_TABLE[delta]);
    return (uint8_t)delta;
}

static int32_t decode_nibble(uint8_t code, int32_t *predictor, int32_t *index) {
    int32_t step = STEP_TABLE[*index];
    *index = clamp_index(*index + INDEX_TABLE[code]);
    const int32_t magnitude = code & 7;
    int32_t difference = step >> 3;
    if ((magnitude & 4) != 0) difference += step;
    if ((magnitude & 2) != 0) difference += step >> 1;
    if ((magnitude & 1) != 0) difference += step >> 2;
    *predictor = clamp_sample(*predictor + ((code & 8) != 0 ? -difference : difference));
    return *predictor;
}

int64_t lac_adpcm(const int64_t *input, size_t input_length,
                  uint8_t *output, size_t output_capacity) {
    if (input == NULL || input_length < 2 || input_length > MAX_ENCODE_SAMPLES + 2u) return -1;
    const int64_t mode = input[0];
    const int64_t count = input[1];
    if (mode == 1) {
        if (count < 0 || count > MAX_ENCODE_SAMPLES || input_length != (size_t)count + 2u) return -1;
        for (size_t i = 0; i < (size_t)count; ++i)
            if (input[i + 2] < -32768 || input[i + 2] > 32767) return -1;
    } else if (mode == 2) {
        if (count < 0 || count > MAX_DECODE_BYTES || input_length != (size_t)count + 2u) return -1;
        for (size_t i = 0; i < (size_t)count; ++i)
            if (input[i + 2] < 0 || input[i + 2] > 255) return -1;
    } else {
        return -1;
    }

    const size_t payload_count = (size_t)count;
    const size_t required = mode == 1 ? (payload_count + 1u) / 2u : payload_count * 4u;
    if (required == 0) return 0;
    if (output == NULL || output_capacity < required) return -2;

    int32_t predictor = 0;
    int32_t index = 0;
    if (mode == 1) {
        for (size_t i = 0; i < payload_count; ++i) {
            const uint8_t code = encode_sample((int32_t)input[i + 2], &predictor, &index);
            if ((i & 1u) == 0) output[i / 2u] = (uint8_t)(code << 4);
            else output[i / 2u] |= code;
        }
    } else {
        for (size_t i = 0; i < payload_count; ++i) {
            const uint8_t packed = (uint8_t)input[i + 2];
            for (size_t half = 0; half < 2; ++half) {
                const uint8_t code = half == 0 ? (uint8_t)(packed >> 4) : (uint8_t)(packed & 15u);
                const uint16_t sample = (uint16_t)decode_nibble(code, &predictor, &index);
                const size_t position = (i * 2u + half) * 2u;
                output[position] = (uint8_t)sample;
                output[position + 1u] = (uint8_t)(sample >> 8);
            }
        }
    }
    return (int64_t)required;
}
