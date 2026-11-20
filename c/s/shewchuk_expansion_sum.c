#include <stddef.h>
#include <stdint.h>

enum { MAX_TERMS = 16, MAX_LENGTH = 34 };
static const int64_t max_mantissa = INT64_C(16777216);
static const double output_scale = 1073741824.0;

static void two_sum(double a, double b, double *high, double *low) {
    const double rounded = a + b;
    const double b_virtual = rounded - a;
    const double a_virtual = rounded - b_virtual;
    const double b_roundoff = b - b_virtual;
    const double a_roundoff = a - a_virtual;
    *high = rounded;
    *low = a_roundoff + b_roundoff;
}

static size_t grow_expansion(const double *expansion, size_t count, double value,
                             double *grown) {
    double q = value;
    size_t grown_count = 0;
    for (size_t i = 0; i < count; ++i) {
        double high, low;
        two_sum(q, expansion[i], &high, &low);
        if (low != 0.0) grown[grown_count++] = low;
        q = high;
    }
    if (q != 0.0 || grown_count == 0) grown[grown_count++] = q;
    return grown_count;
}

int64_t shewchuk_expansion_sum(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_TERMS) return -1;
    const size_t n = (size_t)input[0];
    if (length != 1 + 2 * n) return -1;

    double expansion[MAX_TERMS + 1] = {0.0};
    double grown[MAX_TERMS + 1] = {0.0};
    size_t expansion_count = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t mantissa = input[1 + 2 * i];
        const int64_t exponent = input[2 + 2 * i];
        if (mantissa < -max_mantissa || mantissa > max_mantissa
                || exponent < -30 || exponent > 0) return -1;
        double value = (double)mantissa;
        for (int64_t shift = 0; shift > exponent; --shift) value *= 0.5;
        if (value == 0.0) continue;
        const size_t grown_count = grow_expansion(expansion, expansion_count, value, grown);
        for (size_t j = 0; j < grown_count; ++j) expansion[j] = grown[j];
        expansion_count = grown_count;
    }

    int64_t result = (INT64_C(1) << 58) + 1;
    for (size_t i = 0; i < expansion_count; ++i)
        result += (int64_t)(expansion[i] * output_scale);
    return result;
}
