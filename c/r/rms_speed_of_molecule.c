/* RMS molecular speed: (3 * R * temperature / molar_mass) ** 0.5. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double rms_speed_of_molecule(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t temperature = values[0];
    const int64_t molar_mass = values[1];
    if (temperature < 0 || temperature > 1000 || molar_mass < 1 || molar_mass > 1000)
        return INVALID_RESULT;
    const double numerator = (3.0 * 8.3144598) * (double)temperature;
    return pow(numerator / (double)molar_mass, 0.5);
}
