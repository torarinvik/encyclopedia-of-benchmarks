/* PN junction built-in voltage over bounded integer concentrations. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define BOLTZMANN 1.380649e-23
#define ELECTRON_VOLT 1.602176634e-19
#define INVALID_RESULT (-1.0e300)

double builtin_voltage(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t donor = values[0];
    const int64_t acceptor = values[1];
    const int64_t intrinsic = values[2];
    if (donor < 1 || donor > 1000 || acceptor < 1 || acceptor > 1000 || intrinsic < 1 || intrinsic > 1000 ||
        donor <= intrinsic || acceptor <= intrinsic) return INVALID_RESULT;
    const double ratio = ((double)donor * (double)acceptor) / ((double)intrinsic * (double)intrinsic);
    return BOLTZMANN * 300.0 * log(ratio) / ELECTRON_VOLT;
}
