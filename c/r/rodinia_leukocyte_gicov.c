/* Clean-room bounded GICOV recurrence; complete applicable notice in package LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define GICOV_ELLIPSES 7
#define GICOV_MAX_POINTS 16
#define GICOV_INVALID (-1.0e300)

static float gicov_decode(int64_t raw) { return (float)raw / 1000000.0f; }
static float gicov_add(float a, float b) { return a + b; }
static float gicov_sub(float a, float b) { return a - b; }
static float gicov_mul(float a, float b) { return a * b; }
static float gicov_div(float a, float b) { return a / b; }

double rodinia_leukocyte_gicov(const int64_t *input, size_t length) {
    if (input == NULL || length < 1) return GICOV_INVALID;
    const int64_t points_raw = input[0];
    if (points_raw < 2 || points_raw > GICOV_MAX_POINTS) return GICOV_INVALID;
    const size_t points = (size_t)points_raw;
    if (length != 1 + GICOV_ELLIPSES * points) return GICOV_INVALID;
    for (size_t i = 1; i < length; ++i)
        if (input[i] < -1000000 || input[i] > 1000000) return GICOV_INVALID;

    float maximum = 0.0f;
    for (size_t ellipse = 0; ellipse < GICOV_ELLIPSES; ++ellipse) {
        float sum = 0.0f, mean = 0.0f, m2 = 0.0f;
        const size_t base = 1 + ellipse * points;
        for (size_t n = 0; n < points; ++n) {
            const float p = gicov_decode(input[base + n]);
            sum = gicov_add(sum, p);
            const float delta = gicov_sub(p, mean);
            mean = gicov_add(mean, gicov_div(delta, (float)(n + 1)));
            m2 = gicov_add(m2, gicov_mul(delta, gicov_sub(p, mean)));
        }
        mean = gicov_div(sum, (float)points);
        const float variance = gicov_div(m2, (float)(points - 1));
        if (!(variance > 0.0f) || !isfinite(variance)) return GICOV_INVALID;
        const float score = gicov_div(gicov_mul(mean, mean), variance);
        if (!isfinite(score)) return GICOV_INVALID;
        if (score > maximum) maximum = score;
    }
    return (double)maximum;
}
