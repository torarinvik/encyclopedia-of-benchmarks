/* Solve one quantity in conductivity = electron concentration * mobility * charge. */
#include <stddef.h>
#include <stdint.h>

#define ELECTRON_CHARGE 1.6021e-19
#define INVALID_RESULT (-1.0e300)

double electric_conductivity(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t conductivity = values[0];
    const int64_t electron_conc = values[1];
    const int64_t mobility = values[2];
    if (conductivity < 0 || conductivity > 1000 || electron_conc < 0 || electron_conc > 1000 || mobility < 0 || mobility > 1000) return INVALID_RESULT;
    const int zeros = (conductivity == 0) + (electron_conc == 0) + (mobility == 0);
    if (zeros != 1) return INVALID_RESULT;
    if (conductivity == 0) return (double)mobility * (double)electron_conc * ELECTRON_CHARGE;
    if (electron_conc == 0) return (double)conductivity / ((double)mobility * ELECTRON_CHARGE);
    return (double)conductivity / ((double)electron_conc * ELECTRON_CHARGE);
}
