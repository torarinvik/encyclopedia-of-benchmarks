/* Inductive reactance relation over a bounded integer-valued domain. */
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846
#define INVALID_RESULT (-1.0e300)

double ind_reactance(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t inductance = values[0];
    const int64_t frequency = values[1];
    const int64_t reactance = values[2];
    if (inductance < 0 || inductance > 1000 || frequency < 0 || frequency > 1000 || reactance < 0 || reactance > 1000) return INVALID_RESULT;
    const int zeros = (inductance == 0) + (frequency == 0) + (reactance == 0);
    if (zeros != 1) return INVALID_RESULT;
    if (inductance == 0) return (double)reactance / (2.0 * PI * (double)frequency);
    if (frequency == 0) return (double)reactance / (2.0 * PI * (double)inductance);
    return 2.0 * PI * (double)frequency * (double)inductance;
}
