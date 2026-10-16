#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_SAMPLES 256
#define MAX_LAG 64

double yin(const int64_t *input, size_t length)
{
    if (input == NULL || length < 7 || length > MAX_SAMPLES + 5) return INVALID_RESULT;
    int64_t count_v = input[0], rate_v = input[1], min_hz_v = input[2], max_hz_v = input[3], threshold_v = input[4];
    if (count_v < 2 || count_v > MAX_SAMPLES || length != (size_t)count_v + 5 ||
        rate_v < 1 || rate_v > 192000 || min_hz_v < 1 || max_hz_v <= min_hz_v ||
        max_hz_v > rate_v / 2 || threshold_v < 1 || threshold_v > 999999) return INVALID_RESULT;
    size_t count = (size_t)count_v;
    size_t min_lag = (size_t)(rate_v / max_hz_v);
    size_t max_lag = (size_t)(rate_v / min_hz_v);
    if (min_lag < 1 || min_lag > max_lag || max_lag > MAX_LAG || max_lag >= count) return INVALID_RESULT;
    double samples[MAX_SAMPLES];
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 5] < -32768 || input[i + 5] > 32767) return INVALID_RESULT;
        samples[i] = (double)input[i + 5];
    }
    double difference[MAX_LAG + 1] = {0.0};
    double cmndf[MAX_LAG + 1] = {0.0};
    cmndf[0] = 1.0;
    double sum = 0.0;
    for (size_t lag = 1; lag <= max_lag; ++lag) {
        double diff_sum = 0.0;
        for (size_t i = 0; i < count - lag; ++i) {
            double diff = samples[i] - samples[i + lag];
            diff_sum += diff * diff;
        }
        difference[lag] = diff_sum;
        sum += diff_sum;
        cmndf[lag] = (double)lag * diff_sum / (sum == 0.0 ? 1e-10 : sum);
    }
    double threshold = (double)threshold_v / 1000000.0;
    size_t lag = min_lag;
    while (lag <= max_lag) {
        if (cmndf[lag] < threshold) {
            while (lag < max_lag && cmndf[lag + 1] < cmndf[lag]) ++lag;
            size_t x0 = lag > 0 ? lag - 1 : 0;
            size_t x2 = lag + 1 < max_lag + 1 ? lag + 1 : max_lag;
            double s0 = cmndf[x0], s1 = cmndf[lag], s2 = cmndf[x2];
            double denom = s0 - 2.0 * s1 + s2;
            double refined = denom == 0.0 ? (double)lag : (double)lag + (s0 - s2) / (2.0 * denom);
            if (!(refined > 0.0)) return INVALID_RESULT;
            return (double)rate_v / refined;
        }
        ++lag;
    }
    return INVALID_RESULT;
}
