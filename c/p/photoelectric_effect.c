/* Photoelectric maximum electron kinetic energy in electronvolts. */
#include <stddef.h>
#include <stdint.h>

#define PLANCK_EV 4.1357e-15
#define INVALID_RESULT (-1.0e300)

double photoelectric_effect(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t frequency = values[0];
    const int64_t work_function = values[1];
    if (frequency < 0 || frequency > INT64_C(1000000000000000000) || work_function < 0 || work_function > 1000)
        return INVALID_RESULT;
    const double photon_energy = PLANCK_EV * (double)frequency;
    const double energy_difference = photon_energy - (double)work_function;
    return energy_difference > 0.0 ? energy_difference : 0.0;
}
