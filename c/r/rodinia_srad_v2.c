/* Rodinia SRAD v2 kernel profile; source and license provenance: benchmarks/r/rodinia_srad_v2. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define SRAD_PIXELS 256
#define SRAD_INPUTS (SRAD_PIXELS + 2)
#define LAMBDA_MIN_BITS UINT32_C(0x3c23d70a)
#define LAMBDA_MAX_BITS UINT32_C(0x3dcccccd)
#define Q0_MIN_BITS UINT32_C(0x3c23d70a)
#define Q0_MAX_BITS UINT32_C(0x3f800000)
#define J_MIN_BITS UINT32_C(0x3f800000)
#define J_MAX_BITS UINT32_C(0x3fa00000)

static float srad_f32_bits(uint32_t bits) { float value; memcpy(&value, &bits, sizeof(value)); return value; }
static float srad_add(float a, float b) { volatile float value = a + b; return value; }
static float srad_sub(float a, float b) { volatile float value = a - b; return value; }
static float srad_mul(float a, float b) { volatile float value = a * b; return value; }
static float srad_div(float a, float b) { volatile float value = a / b; return value; }

int64_t rodinia_srad_v2(const int64_t *values, size_t length) {
    if (values == NULL || length != SRAD_INPUTS) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < 0 || (uint64_t)values[i] > UINT32_MAX) return -1;
    uint32_t lambda_bits = (uint32_t)values[0], q0_bits = (uint32_t)values[1];
    if (lambda_bits < LAMBDA_MIN_BITS || lambda_bits > LAMBDA_MAX_BITS ||
        q0_bits < Q0_MIN_BITS || q0_bits > Q0_MAX_BITS) return -1;

    float lambda = srad_f32_bits(lambda_bits), q0sqr = srad_f32_bits(q0_bits);
    float image[SRAD_PIXELS], coeff[SRAD_PIXELS];
    float north[SRAD_PIXELS], south[SRAD_PIXELS], west[SRAD_PIXELS], east[SRAD_PIXELS];
    for (size_t i = 0; i < SRAD_PIXELS; ++i) {
        uint32_t bits = (uint32_t)values[i + 2];
        if (bits < J_MIN_BITS || bits > J_MAX_BITS) return -1;
        image[i] = srad_f32_bits(bits);
    }

    for (size_t row = 0; row < 16; ++row) for (size_t col = 0; col < 16; ++col) {
        size_t i = row * 16 + col;
        float jc = image[i];
        float n = srad_sub(image[(row ? row - 1 : row) * 16 + col], jc);
        float s = srad_sub(image[(row < 15 ? row + 1 : row) * 16 + col], jc);
        float w = srad_sub(image[row * 16 + (col ? col - 1 : col)], jc);
        float e = srad_sub(image[row * 16 + (col < 15 ? col + 1 : col)], jc);
        north[i] = n; south[i] = s; west[i] = w; east[i] = e;
        float gradient = srad_add(srad_add(srad_add(srad_mul(n,n), srad_mul(s,s)), srad_mul(w,w)), srad_mul(e,e));
        gradient = srad_div(gradient, srad_mul(jc,jc));
        float laplacian = srad_div(srad_add(srad_add(srad_add(n,s),w),e), jc);
        float lap_sq = srad_mul(laplacian, laplacian);
        float num = (float)(0.5 * (double)gradient - (1.0 / 16.0) * (double)lap_sq);
        float den = (float)(1.0 + 0.25 * (double)laplacian);
        if (den == 0.0f) return -1;
        float qsqr = srad_div(num, srad_mul(den,den));
        den = srad_div(srad_sub(qsqr,q0sqr), srad_mul(q0sqr,srad_add(1.0f,q0sqr)));
        if (den == -1.0f) return -1;
        float c = (float)(1.0 / (1.0 + (double)den));
        if (!isfinite(c)) return -1;
        coeff[i] = c < 0.0f ? 0.0f : c > 1.0f ? 1.0f : c;
    }

    int64_t checksum = 0;
    for (size_t row = 0; row < 16; ++row) for (size_t col = 0; col < 16; ++col) {
        size_t i = row * 16 + col;
        float cc = coeff[i];
        float cs = coeff[(row < 15 ? row + 1 : row) * 16 + col];
        float ce = coeff[row * 16 + (col < 15 ? col + 1 : col)];
        float divergence = srad_add(srad_add(srad_add(srad_mul(cc,north[i]), srad_mul(cs,south[i])),
                                               srad_mul(cc,west[i])), srad_mul(ce,east[i]));
        float updated = (float)((double)image[i] + 0.25 * (double)lambda * (double)divergence);
        if (!isfinite(updated) || updated < 0.0f) return -1;
        checksum += (int64_t)((double)updated * 1000000.0 + 0.5);
    }
    return checksum;
}
