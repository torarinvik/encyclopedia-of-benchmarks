#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_CASH_FLOWS INT64_C(8)
#define MAX_RATE_PPM INT64_C(1000000)
#define MAX_CASH_FLOW_MILLI INT64_C(1000000)
#define MAX_INPUT_LENGTH 11
#define INVALID_RESULT (-1.0e300)

double present_value_rust(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t count = values[0];
    const int64_t rate_ppm = values[1];
    if (count < 1 || count > MAX_CASH_FLOWS || length != (size_t)count + 2 ||
        (rate_ppm != 0 && rate_ppm != MAX_RATE_PPM)) return INVALID_RESULT;

    const double discount_rate = (double)rate_ppm / 1000000.0;
    double present_value = 0.0;
    for (int64_t index = 0; index < count; ++index) {
        const int64_t cash_flow_milli = values[(size_t)index + 2];
        if (cash_flow_milli < -MAX_CASH_FLOW_MILLI || cash_flow_milli > MAX_CASH_FLOW_MILLI ||
            cash_flow_milli % 125 != 0)
            return INVALID_RESULT;
        const double cash_flow = (double)cash_flow_milli / 1000.0;
        present_value += cash_flow / pow(1.0 + discount_rate, (double)index);
    }
    return round(present_value * 100.0) / 100.0;
}
