#include <math.h>

static float f32_mul(float a, float b) { volatile float r = a * b; return r; }
static float f32_sub(float a, float b) { volatile float r = a - b; return r; }
static float f32_div(float a, float b) { volatile float r = a / b; return r; }

double newton_raphson_root(double x0) {
    if (!isfinite(x0) || x0 < 1.0 || x0 > 4.0) return -1e300;
    float x = (float)x0;
    for (int i = 0; i < 1000; ++i) {
        float residual = f32_sub(f32_mul(x, x), 3.0f);
        if (fabsf(residual) <= 1e-6f) return (double)x;
        float derivative = f32_mul(2.0f, x);
        if (derivative == 0.0f) return -1e300;
        x = f32_sub(x, f32_div(residual, derivative));
    }
    return (double)x;
}
