/* Net present value with source-ordered binary64 terms. */
#include <stddef.h>
#include <stdint.h>
#include <math.h>

static const double INVALID = -1e300;
double npv(const int64_t *input, size_t length) {
    if (!input || length < 2 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 1000 || length != (size_t)input[0] + 2) return INVALID;
    size_t n = (size_t)input[0];
    for (size_t t=0;t<n;++t) if (input[t+2] < -1000000 || input[t+2] > 1000000) return INVALID;
    double rate = (double)input[1] / 10000.0;
    double total = 0.0;
    for (size_t t=0;t<n;++t) {
        double term = (double)input[t+2] / pow(1.0 + rate, (double)t);
        total += term;
    }
    return total;
}
