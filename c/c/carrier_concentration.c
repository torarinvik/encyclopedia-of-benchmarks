/* Solve the missing semiconductor carrier concentration. */
#include <stddef.h>
#include <stdint.h>
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double carrier_concentration(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t electron_conc = values[0];
    const int64_t hole_conc = values[1];
    const int64_t intrinsic_conc = values[2];
    if (electron_conc < 0 || electron_conc > 1000000 || hole_conc < 0 || hole_conc > 1000000 ||
        intrinsic_conc < 0 || intrinsic_conc > 1000000)
        return INVALID_RESULT;
    const int zero_count = (electron_conc == 0) + (hole_conc == 0) + (intrinsic_conc == 0);
    if (zero_count != 1) return INVALID_RESULT;
    if (electron_conc == 0)
        return (double)(intrinsic_conc * intrinsic_conc) / (double)hole_conc;
    if (hole_conc == 0)
        return (double)(intrinsic_conc * intrinsic_conc) / (double)electron_conc;
    return pow((double)(electron_conc * hole_conc), 0.5);
}
