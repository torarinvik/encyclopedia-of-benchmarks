/*
 * This source code is a product of Sun Microsystems, Inc. and is provided
 * for unrestricted use.  Users may copy or modify this source code without
 * charge.
 *
 * SUN SOURCE CODE IS PROVIDED AS IS WITH NO WARRANTIES OF ANY KIND INCLUDING
 * THE WARRANTIES OF DESIGN, MERCHANTIBILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE, OR ARISING FROM A COURSE OF DEALING, USAGE OR TRADE PRACTICE.
 *
 * Sun source code is provided with no support and without any obligation on
 * the part of Sun Microsystems, Inc. to assist in its use, correction,
 * modification or enhancement.
 *
 * SUN MICROSYSTEMS, INC. SHALL HAVE NO LIABILITY WITH RESPECT TO THE
 * INFRINGEMENT OF COPYRIGHTS, TRADE SECRETS OR ANY PATENTS BY THIS SOFTWARE
 * OR ANY PART THEREOF.
 *
 * In no event will Sun Microsystems, Inc. be liable for any lost revenue
 * or profits or other special, indirect and consequential damages, even if
 * Sun has been advised of the possibility of such damages.
 *
 * Sun Microsystems, Inc.
 * 2550 Garcia Avenue
 * Mountain View, California  94043
 */

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

enum { MAX_SAMPLES = 16, MAX_INPUT = MAX_SAMPLES + 1 };

typedef struct {
    int64_t yl, yu, dms, dml, ap;
    int64_t a[2], b[6], pk[2], dq[6], sr[2], td;
} g721_state;

static const int64_t power2[15] = {
    1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384
};
static const int64_t qtab[7] = {-124, 80, 178, 246, 300, 349, 400};
static const int64_t dqlntab[16] = {
    -2048, 4, 135, 213, 273, 323, 373, 425,
    425, 373, 323, 273, 213, 135, 4, -2048
};
static const int64_t witab[16] = {
    -12, 18, 41, 64, 112, 198, 355, 1122,
    1122, 355, 198, 112, 64, 41, 18, -12
};
static const int64_t fitab[16] = {
    0, 0, 0, 512, 512, 512, 1536, 3584,
    3584, 1536, 512, 512, 512, 0, 0, 0
};

static int64_t wrap16(int64_t value) {
    const uint64_t low = (uint64_t)value & UINT64_C(0xffff);
    return low >= UINT64_C(0x8000) ? (int64_t)low - 65536 : (int64_t)low;
}

static int64_t quant_table(int64_t value, const int64_t *table, int count) {
    int i;
    for (i = 0; i < count; ++i) if (value < table[i]) break;
    return i;
}

static int64_t fmult(int64_t coefficient, int64_t encoded) {
    const int64_t magnitude = coefficient > 0 ? coefficient : ((-coefficient) & 0x1fff);
    const int64_t exponent = quant_table(magnitude, power2, 15) - 6;
    const int64_t mantissa = magnitude == 0 ? 32 :
        (exponent >= 0 ? magnitude >> exponent : magnitude << -exponent);
    const int64_t product_exponent = exponent + ((encoded >> 6) & 0x0f) - 13;
    const int64_t product_mantissa = (mantissa * (encoded & 077) + 0x30) >> 4;
    const int64_t result = product_exponent >= 0 ?
        ((product_mantissa << product_exponent) & 0x7fff) :
        (product_mantissa >> -product_exponent);
    return ((coefficient ^ encoded) < 0) ? -result : result;
}

static int64_t predictor_zero(const g721_state *state) {
    int i;
    int64_t sum = fmult(state->b[0] >> 2, state->dq[0]);
    for (i = 1; i < 6; ++i) sum += fmult(state->b[i] >> 2, state->dq[i]);
    return sum;
}

static int64_t predictor_pole(const g721_state *state) {
    return fmult(state->a[1] >> 2, state->sr[1]) + fmult(state->a[0] >> 2, state->sr[0]);
}

static int64_t step_size(const g721_state *state) {
    int64_t y, difference, weight;
    if (state->ap >= 256) return state->yu;
    y = state->yl >> 6;
    difference = state->yu - y;
    weight = state->ap >> 2;
    if (difference > 0) y += (difference * weight) >> 6;
    else if (difference < 0) y += (difference * weight + 0x3f) >> 6;
    return y;
}

static int64_t quantize(int64_t difference, int64_t step) {
    const int64_t magnitude = difference < 0 ? -difference : difference;
    const int64_t exponent = quant_table(magnitude >> 1, power2, 15);
    const int64_t mantissa = ((magnitude << 7) >> exponent) & 0x7f;
    const int64_t log_magnitude = (exponent << 7) + mantissa;
    const int64_t normalized = log_magnitude - (step >> 2);
    const int64_t index = quant_table(normalized, qtab, 7);
    if (difference < 0) return 15 - index;
    return index == 0 ? 15 : index;
}

static int64_t reconstruct(int64_t sign, int64_t log_difference, int64_t step) {
    const int64_t log_value = log_difference + (step >> 2);
    int64_t exponent, mantissa, value;
    if (log_value < 0) return sign ? -32768 : 0;
    exponent = (log_value >> 7) & 15;
    mantissa = 128 + (log_value & 127);
    value = (mantissa << 7) >> (14 - exponent);
    return sign ? value - 32768 : value;
}

static void update_state(int64_t step, int64_t wi, int64_t fi, int64_t dq,
                         int64_t sr, int64_t dqsez, g721_state *state) {
    int i;
    int64_t magnitude = dq & 0x7fff;
    int64_t ylint = state->yl >> 15;
    int64_t ylfrac = (state->yl >> 10) & 0x1f;
    int64_t threshold1 = (32 + ylfrac) << ylint;
    int64_t threshold2 = ylint > 9 ? 31 << 10 : threshold1;
    int64_t dq_threshold = (threshold2 + (threshold2 >> 1)) >> 1;
    int64_t transition = state->td != 0 && magnitude > dq_threshold;

    state->yu = wrap16(step + ((wi - step) >> 5));
    if (state->yu < 544) state->yu = 544;
    else if (state->yu > 5120) state->yu = 5120;
    state->yl += state->yu + ((-state->yl) >> 6);

    if (transition) {
        state->a[0] = state->a[1] = 0;
        for (i = 0; i < 6; ++i) state->b[i] = 0;
    } else {
        int64_t pk0 = dqsez < 0 ? 1 : 0;
        int64_t pks1 = pk0 ^ state->pk[0];
        int64_t a2p = state->a[1] - (state->a[1] >> 7);
        int64_t fa1;
        if (dqsez != 0) {
            fa1 = pks1 ? state->a[0] : -state->a[0];
            if (fa1 < -8191) a2p -= 0x100;
            else if (fa1 > 8191) a2p += 0xff;
            else a2p += fa1 >> 5;
            if (pk0 ^ state->pk[1]) {
                if (a2p <= -12160) a2p = -12288;
                else if (a2p >= 12416) a2p = 12288;
                else a2p -= 0x80;
            } else {
                if (a2p <= -12416) a2p = -12288;
                else if (a2p >= 12160) a2p = 12288;
                else a2p += 0x80;
            }
        }
        a2p = wrap16(a2p);
        state->a[1] = wrap16(a2p);
        state->a[0] -= state->a[0] >> 8;
        state->a[0] = wrap16(state->a[0]);
        if (dqsez != 0) state->a[0] += pks1 == 0 ? 192 : -192;
        state->a[0] = wrap16(state->a[0]);
        {
            int64_t limit = 15360 - a2p;
            if (state->a[0] < -limit) state->a[0] = -limit;
            else if (state->a[0] > limit) state->a[0] = limit;
        }
        state->a[0] = wrap16(state->a[0]);
        for (i = 0; i < 6; ++i) {
            state->b[i] -= state->b[i] >> 8;
            state->b[i] = wrap16(state->b[i]);
            if (dq & 0x7fff) {
                if ((dq ^ state->dq[i]) >= 0) state->b[i] += 128;
                else state->b[i] -= 128;
            }
            state->b[i] = wrap16(state->b[i]);
        }
    }

    for (i = 5; i > 0; --i) state->dq[i] = state->dq[i - 1];
    if (magnitude == 0) state->dq[0] = dq >= 0 ? 0x20 : wrap16(0xfc20);
    else {
        int64_t exponent = quant_table(magnitude, power2, 15);
        int64_t encoded = (exponent << 6) + ((magnitude << 6) >> exponent);
        state->dq[0] = wrap16(dq >= 0 ? encoded : encoded - 0x400);
    }
    state->sr[1] = state->sr[0];
    if (sr == 0) state->sr[0] = 0x20;
    else if (sr > 0) {
        int64_t exponent = quant_table(sr, power2, 15);
        state->sr[0] = wrap16((exponent << 6) + ((sr << 6) >> exponent));
    } else if (sr > -32768) {
        int64_t abs_sr = -sr;
        int64_t exponent = quant_table(abs_sr, power2, 15);
        state->sr[0] = wrap16((exponent << 6) + ((abs_sr << 6) >> exponent) - 0x400);
    } else state->sr[0] = wrap16(0xfc20);

    state->pk[1] = state->pk[0];
    state->pk[0] = dqsez < 0 ? 1 : 0;
    if (transition) state->td = 0;
    else if (state->a[1] < -11776) state->td = 1;
    else state->td = 0;

    state->dms = wrap16(state->dms + ((fi - state->dms) >> 5));
    state->dml = wrap16(state->dml + (((fi << 2) - state->dml) >> 7));
    if (transition) state->ap = 256;
    else if (step < 1536 || state->td == 1 ||
             llabs((state->dms << 2) - state->dml) >= (state->dml >> 3))
        state->ap = wrap16(state->ap + ((0x200 - state->ap) >> 4));
    else state->ap = wrap16(state->ap + ((-state->ap) >> 4));
}

static void init_state(g721_state *state) {
    int i;
    state->yl = 34816;
    state->yu = 544;
    state->dms = state->dml = state->ap = 0;
    state->td = 0;
    for (i = 0; i < 2; ++i) {
        state->a[i] = state->pk[i] = 0;
        state->sr[i] = 32;
    }
    for (i = 0; i < 6; ++i) state->b[i] = 0, state->dq[i] = 32;
}

static int64_t ulaw_to_linear(int64_t input) {
    const int64_t value = (~input) & 0xff;
    int64_t sample = ((value & 0x0f) << 3) + 0x84;
    sample <<= (value & 0x70) >> 4;
    return (value & 0x80) ? 0x84 - sample : sample - 0x84;
}

static int64_t encode_one(int64_t input, g721_state *state) {
    int64_t sample = ulaw_to_linear(input) >> 2;
    int64_t sezi = wrap16(predictor_zero(state));
    int64_t sez = sezi >> 1;
    int64_t se = wrap16((sezi + predictor_pole(state)) >> 1);
    int64_t difference = wrap16(sample - se);
    int64_t step = wrap16(step_size(state));
    int64_t code = quantize(difference, step);
    int64_t dq = wrap16(reconstruct(code & 8, dqlntab[code], step));
    int64_t sr = wrap16(dq < 0 ? se - (dq & 0x3fff) : se + dq);
    int64_t dqsez = wrap16(sr + sez - se);
    update_state(step, witab[code] << 5, fitab[code], dq, sr, dqsez, state);
    return code;
}

int64_t mediabench_g721_encode(const int64_t *input, size_t input_length,
                               uint8_t *output, size_t output_capacity) {
    g721_state state;
    size_t count, required, i;
    if (input == NULL || input_length < 1 || input_length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_SAMPLES) return -1;
    count = (size_t)input[0];
    if (input_length != count + 1) return -1;
    for (i = 0; i < count; ++i) if (input[i + 1] < 0 || input[i + 1] > 255) return -1;
    required = (count + 1) / 2;
    if (required == 0) return 0;
    if (output == NULL || output_capacity < required) return -2;
    init_state(&state);
    for (i = 0; i < count; ++i) {
        const uint8_t code = (uint8_t)encode_one(input[i + 1], &state);
        if ((i & 1u) == 0) output[i / 2] = code;
        else output[i / 2] |= (uint8_t)(code << 4);
    }
    return (int64_t)required;
}
