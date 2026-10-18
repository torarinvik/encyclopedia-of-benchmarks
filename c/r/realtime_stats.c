#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1e300)
#define MAX_INPUT_LENGTH 36
#define MAX_SAMPLES 32

double realtime_stats(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t variant = values[0];
    const int64_t statistic = values[1];
    const int64_t count = values[2];
    if (variant < 0 || variant > 2 || statistic < 0 || statistic > 2 ||
        count < 2 || count > MAX_SAMPLES || length != (size_t)(3 + count))
        return INVALID_RESULT;
    for (size_t i = 0; i < (size_t)count; ++i)
        if (values[3 + i] < -64 || values[3 + i] > 64) return INVALID_RESULT;

    float mean32 = 0.0f;
    float variance32 = 0.0f;
    double mean64 = 0.0;
    double variance64 = 0.0;

    if (variant == 0) {
        float anchor = 0.0f;
        float ex = 0.0f;
        float ex2 = 0.0f;
        unsigned int n = 0;
        for (size_t i = 0; i < (size_t)count; ++i) {
            const float x = (float)values[3 + i] / 16.0f;
            if (n == 0) anchor = x;
            ++n;
            const float tmp = x - anchor;
            ex += tmp;
            ex2 += tmp * tmp;
        }
        mean32 = anchor + ex / (float)n;
        variance32 = (ex2 - (ex * ex) / (float)n) / (float)(n - 1);
    } else if (variant == 1) {
        float mu = 0.0f;
        float m = 0.0f;
        unsigned int n = 0;
        for (size_t i = 0; i < (size_t)count; ++i) {
            const float x = (float)values[3 + i] / 16.0f;
            ++n;
            const float delta = x - mu;
            mu += delta / (float)n;
            const float delta2 = x - mu;
            m += delta * delta2;
        }
        mean32 = mu;
        variance32 = m / (float)n;
    } else {
        double mu = 0.0;
        double m = 0.0;
        unsigned int n = 0;
        for (size_t i = 0; i < (size_t)count; ++i) {
            const float x32 = (float)values[3 + i] / 16.0f;
            const double x = (double)x32;
            ++n;
            const double delta = x - mu;
            mu += delta / (double)n;
            const double delta2 = x - mu;
            m += delta * delta2;
        }
        mean64 = mu;
        variance64 = m / (double)n;
    }

    if (variant < 2) {
        if (statistic == 0) return (double)mean32;
        if (statistic == 1) return (double)variance32;
        return (double)sqrtf(variance32);
    }
    if (statistic == 0) return mean64;
    if (statistic == 1) return variance64;
    return sqrt(variance64);
}
