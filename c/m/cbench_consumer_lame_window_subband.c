/*
 * Copyright (c) 1999 Takehiro TOMINAGA
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define SAMPLE_COUNT 511u
#define WINDOW_COUNT 256u
#define INPUT_COUNT (SAMPLE_COUNT + WINDOW_COUNT)
#define MAX_INPUT_LENGTH (INPUT_COUNT + 1u)
#define BAND_COUNT 32u
#define OUTPUT_BYTES (BAND_COUNT * 8u)
#define PI 3.14159265358979323846264338327950288
#define WINDOW_SCALE 1000000000.0
#define RESULT_SCALE 1000.0

static const int s_offsets[15] = {334,398,462,14,78,142,206,16,80,144,208,272,336,400,464};
static const int t_offsets[15] = {176,112,48,496,432,368,304,494,430,366,302,238,174,110,46};

static void store_i64_le(uint8_t *out, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8u; ++byte) {
        out[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int64_t round_q1000(double value)
{
    double scaled = value * RESULT_SCALE;
    double magnitude = scaled < 0.0 ? -scaled : scaled;
    int64_t rounded = (int64_t)(magnitude + 0.5);
    return scaled < 0.0 ? -rounded : rounded;
}

static int valid_input(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0u || length > MAX_INPUT_LENGTH || length != INPUT_COUNT) return 0;
    for (size_t i = 0; i < SAMPLE_COUNT; ++i)
        if (input[i] < -32768 || input[i] > 32767) return 0;
    for (size_t i = 0; i < WINDOW_COUNT; ++i)
        if (input[SAMPLE_COUNT + i] < -4500000 || input[SAMPLE_COUNT + i] > 36000000) return 0;
    for (size_t i = 0; i < WINDOW_COUNT; ++i) {
        if ((i == 0u || (i >= 8u && (i - 8u) % 16u == 0u))
            && input[SAMPLE_COUNT + i] <= 25000000) return 0;
    }
    return 1;
}

static void window_subband(const int64_t *input, double window[WINDOW_COUNT], double output[BAND_COUNT])
{
    double max = window[248];
    double mmax[31];
    double mm[16][31];
    size_t wp = 0u, wr = 0u;
    double w = window[wp++];
    mmax[15] = w / max;
    for (size_t k = 0; k < 7u; ++k) window[wr++] = window[wp++] / w;
    for (int i = 14; i >= 0; --i) {
        w = window[wp++];
        mmax[i] = w / max;
        mmax[30 - i] = w / max;
        for (size_t k = 0; k < 15u; ++k) window[wr++] = window[wp++] / w;
    }
    ++wp;
    for (size_t k = 0; k < 7u; ++k) window[wr++] = window[wp++] / max;

    for (int i = 15; i >= 0; --i)
        for (int k = 1; k < 32; ++k)
            mm[i][k - 1] = cos((2 * i + 1) * k * PI / 64.0) * mmax[k - 1];

    double intermediate[31] = {0.0};
    size_t coeff = 0u;
    double t = (double)input[255];
    t += (double)(input[223] - input[287]) * window[coeff++];
    t += (double)(input[191] + input[319]) * window[coeff++];
    t += (double)(input[159] - input[351]) * window[coeff++];
    t += (double)(input[127] + input[383]) * window[coeff++];
    t += (double)(input[95] - input[415]) * window[coeff++];
    t += (double)(input[63] + input[447]) * window[coeff++];
    t += (double)(input[31] - input[479]) * window[coeff++];
    intermediate[15] = t;

    for (int i = 14; i >= 0; --i) {
        double s = (double)input[270 - i];
        t = (double)input[240 + i];
        for (int k = 0; k < 15; ++k) {
            w = window[coeff++];
            double sv = (double)input[(size_t)(s_offsets[k] + (k < 7 ? -i : i))];
            double tv = (double)input[(size_t)(t_offsets[k] + (k < 7 ? i : -i))];
            if (k >= 11) s -= sv * w;
            else s += sv * w;
            if (k >= 7 && k < 11) t -= tv * w;
            else t += tv * w;
        }
        intermediate[30 - i] = s;
        intermediate[i] = t;
    }

    double s = (double)input[239];
    s += (double)input[175] * window[coeff++];
    s += (double)input[111] * window[coeff++];
    s += (double)input[47] * window[coeff++];
    s -= (double)input[303] * window[coeff++];
    s -= (double)input[367] * window[coeff++];
    s -= (double)input[431] * window[coeff++];
    s -= (double)input[495] * window[coeff++];

    for (int i = 15; i >= 0; --i) {
        double s0 = s;
        double s1 = t * mm[i][0];
        size_t at = 1u;
        for (int j = 0; j < 15; ++j) {
            s0 += mm[i][2 * j + 1] * intermediate[at++];
            s1 += mm[i][2 * j + 2] * intermediate[at++];
        }
        output[i] = s0 + s1;
        output[31 - i] = s0 - s1;
    }
}

int64_t cbench_consumer_lame_window_subband(const int64_t *input, size_t input_length,
                                             uint8_t *output, size_t output_capacity)
{
    if (!valid_input(input, input_length)) return -1;
    double window[WINDOW_COUNT];
    for (size_t i = 0; i < WINDOW_COUNT; ++i)
        window[i] = (double)input[SAMPLE_COUNT + i] / WINDOW_SCALE;
    double bands[BAND_COUNT];
    window_subband(input, window, bands);
    int64_t staged[BAND_COUNT];
    for (size_t i = 0; i < BAND_COUNT; ++i) staged[i] = round_q1000(bands[i]);
    if (output == NULL || output_capacity < OUTPUT_BYTES) return -2;
    for (size_t i = 0; i < BAND_COUNT; ++i) store_i64_le(output, 8u * i, staged[i]);
    return OUTPUT_BYTES;
}
