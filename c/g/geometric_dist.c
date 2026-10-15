#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static float geometric_cdf(float p, int64_t k)
{
    return 1.0f - powf(1.0f - p, (float)k);
}

/* Deterministic operations of the source's first-success geometric distribution. */
double geometric_dist(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t operation = values[0];
    const int64_t p_code = values[1];
    if (p_code < 0 || p_code > 2) return INVALID_RESULT;
    const float probabilities[] = {0.25f, 0.5f, 0.75f};
    const float p = probabilities[p_code];
    if (operation >= 0 && operation <= 2) {
        if (length != 2) return INVALID_RESULT;
        if (operation == 0) return (double)(1.0f / p);
        const float variance = (1.0f - p) / (p * p);
        return (double)(operation == 1 ? variance : sqrtf(variance));
    }
    if (operation == 3 || operation == 4) {
        if (length != 3) return INVALID_RESULT;
        const int64_t k = values[2];
        if (operation == 3 && (k < 1 || k > 16)) return INVALID_RESULT;
        if (operation == 4 && (k < 0 || k > 16)) return INVALID_RESULT;
        if (operation == 3) return (double)(powf(1.0f - p, (float)(k - 1)) * p);
        return (double)geometric_cdf(p, k);
    }
    if (operation == 5) {
        if (length != 3 || values[2] < 0 || values[2] > 2) return INVALID_RESULT;
        const float cdf_values[] = {0.25f, 0.5f, 0.75f};
        const float cdf = cdf_values[values[2]];
        return (double)(logf(1.0f - cdf) / logf(1.0f - p));
    }
    if (operation == 6) {
        if (length != 4) return INVALID_RESULT;
        const int64_t minimum = values[2];
        const int64_t maximum = values[3];
        if (minimum < 1 || maximum < minimum || maximum > 16) return INVALID_RESULT;
        const float lower = geometric_cdf(p, minimum - 1);
        const float upper = geometric_cdf(p, maximum);
        return (double)(upper - lower);
    }
    return INVALID_RESULT;
}
