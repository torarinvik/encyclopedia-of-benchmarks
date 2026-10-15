/* Solve one ideal-gas-law variable using a portable operation selector. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double ideal_gas_law(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t operation = values[0];
    const int64_t a = values[1], b = values[2], c = values[3];
    if (operation < 0 || operation > 3 || a < 0 || a > 1000 || b < 0 || b > 1000 || c < 0 || c > 1000)
        return INVALID_RESULT;
    switch (operation) {
        case 0: /* pressure_of_gas_system(moles, kelvin, volume) */
        case 1: /* volume_of_gas_system(moles, kelvin, pressure) */
            if (c == 0) return INVALID_RESULT;
            return ((double)a * (double)b * 8.314462) / (double)c;
        case 2: /* temperature_of_gas_system(moles, volume, pressure) */
            if (a == 0) return INVALID_RESULT;
            return ((double)c * (double)b) / ((double)a * 8.314462);
        default: /* moles_of_gas_system(kelvin, volume, pressure) */
            if (a == 0) return INVALID_RESULT;
            return ((double)c * (double)b) / ((double)a * 8.314462);
    }
}
