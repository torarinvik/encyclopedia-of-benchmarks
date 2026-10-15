/* Real/reactive power from apparent power and power factor. */
#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double real_and_reactive_power(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t operation = values[0];
    const int64_t apparent_power = values[1];
    const int64_t factor_units = values[2];
    if ((operation != 0 && operation != 1) || apparent_power < -1000000000LL ||
        apparent_power > 1000000000LL || factor_units < -10000 || factor_units > 10000)
        return INVALID_RESULT;
    const double power_factor = (double)factor_units / 10000.0;
    if (operation == 0) return (double)apparent_power * power_factor;
    return (double)apparent_power * sqrt(1.0 - pow(power_factor, 2.0));
}
