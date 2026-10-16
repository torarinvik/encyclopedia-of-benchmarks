#include <math.h>
#include <stdint.h>
#include <string.h>

#define MIN_VALUE 1e-6
#define MAX_VALUE 1e6

static float newton_step(float x2, float y) {
    volatile float product1 = x2 * y;
    volatile float product2 = product1 * y;
    volatile float correction = 1.5f - product2;
    return y * correction;
}

/* Reciprocal of the pinned Go binary32 fast-inverse-square-root result. */
double go_sqrt_f32(double value) {
    if (!isfinite(value) || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    const float number = (float)value;
    const float x2 = number * 0.5f;
    uint32_t bits;
    memcpy(&bits, &number, sizeof(bits));
    bits = UINT32_C(0x5f3759df) - (bits >> 1);
    float inverse_root;
    memcpy(&inverse_root, &bits, sizeof(inverse_root));
    inverse_root = newton_step(x2, inverse_root);
    inverse_root = newton_step(x2, inverse_root);
    const float root = 1.0f / inverse_root;
    return (double)root;
}
