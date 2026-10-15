#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double ncr_combinations(double total, double choose) {
    if (total != total || choose != choose || total < 0.0 || total > 20.0 ||
        choose < 0.0 || choose > 12.0 || choose != (double)(int64_t)choose) {
        return INVALID_RESULT;
    }

    const int64_t count = (int64_t)choose;
    double numerator = 1.0;
    for (int64_t index = 0; index < count; ++index) {
        numerator *= total - (double)index;
    }
    double denominator = 1.0;
    for (int64_t factor = 2; factor <= count; ++factor) {
        denominator *= (double)factor;
    }
    return numerator / denominator;
}
