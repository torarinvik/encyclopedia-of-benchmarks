/* LC resonant frequency over bounded integer-valued inputs. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846
#define INVALID_RESULT (-1.0e300)

double resonant_frequency(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t inductance = values[0];
    const int64_t capacitance = values[1];
    if (inductance < 1 || inductance > 1000 || capacitance < 1 || capacitance > 1000) return INVALID_RESULT;
    return 1.0 / (2.0 * PI * sqrt((double)inductance * (double)capacitance));
}
