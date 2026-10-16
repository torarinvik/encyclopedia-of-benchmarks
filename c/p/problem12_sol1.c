#include <stdint.h>

static int64_t problem12_sol1_divisor_count(int64_t value)
{
    int64_t count = 1;
    for (int64_t factor = 2; factor <= value / factor; ++factor) {
        int64_t multiplicity = 0;
        while (value % factor == 0) {
            value /= factor;
            ++multiplicity;
        }
        if (multiplicity != 0) count *= multiplicity + 1;
    }
    if (value > 1) count *= 2;
    return count;
}

int64_t problem12_sol1(int64_t threshold)
{
    if (threshold != 500) return -1;

    int64_t index = 1;
    int64_t triangular = 1;
    for (;;) {
        ++index;
        triangular += index;
        if (problem12_sol1_divisor_count(triangular) > 500) return triangular;
    }
}
