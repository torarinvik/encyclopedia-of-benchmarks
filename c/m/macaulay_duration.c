#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_FACE_VALUE_MICRO INT64_C(1000000000000)
#define MAX_RATE_MICRO INT64_C(1000000)
#define MAX_PERIODS INT64_C(64)
#define MAX_INPUT_LENGTH 5
#define INVALID_RESULT (-1.0e300)

double macaulay_duration(const int64_t *values, size_t length) {
    if (values == NULL || length != 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t face_micro = values[0], coupon_micro = values[1];
    const int64_t periods = values[2], yield_micro = values[3];
    if (face_micro < 1 || face_micro > MAX_FACE_VALUE_MICRO
            || coupon_micro < 0 || coupon_micro > MAX_RATE_MICRO
            || periods < 1 || periods > MAX_PERIODS
            || yield_micro < 1 || yield_micro > MAX_RATE_MICRO) return INVALID_RESULT;
    const double face_value = (double)face_micro / (double)SCALE;
    const double coupon_rate = (double)coupon_micro / (double)SCALE;
    const double yield_rate = (double)yield_micro / (double)SCALE;
    double total_present_value = 0.0, total_time_weighted_value = 0.0;
    for (int64_t period = 1; period <= periods; ++period) {
        const double cash_flow = face_value * coupon_rate + (period == periods ? face_value : 0.0);
        const double time_weighted_value = ((double)period * cash_flow) / pow(1.0 + yield_rate, (double)period);
        total_time_weighted_value += time_weighted_value;
        const double present_value = cash_flow / pow(1.0 + yield_rate, (double)period);
        total_present_value += present_value;
    }
    return total_time_weighted_value / total_present_value;
}
