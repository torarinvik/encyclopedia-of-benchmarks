/* Pressure from the ideal gas law: n * T * R / V. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double ideal_gas_law(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t moles = values[0];
    const int64_t kelvin = values[1];
    const int64_t volume = values[2];
    if (moles < 0 || moles > 1000 || kelvin < 0 || kelvin > 1000 || volume < 1 || volume > 1000)
        return INVALID_RESULT;
    return ((double)moles * (double)kelvin * 8.314462) / (double)volume;
}
