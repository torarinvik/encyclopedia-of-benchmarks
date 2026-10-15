/* Solve impedance, resistance, or reactance from the other two values. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double electrical_impedance(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t resistance = values[0];
    const int64_t reactance = values[1];
    const int64_t impedance = values[2];
    if (resistance < 0 || resistance > 1000 || reactance < 0 || reactance > 1000 || impedance < 0 || impedance > 1000)
        return INVALID_RESULT;
    const int zeros = (resistance == 0) + (reactance == 0) + (impedance == 0);
    if (zeros != 1) return INVALID_RESULT;
    double radicand;
    if (resistance == 0) {
        radicand = (double)impedance * (double)impedance - (double)reactance * (double)reactance;
    } else if (reactance == 0) {
        radicand = (double)impedance * (double)impedance - (double)resistance * (double)resistance;
    } else {
        radicand = (double)resistance * (double)resistance + (double)reactance * (double)reactance;
    }
    return radicand < 0.0 ? INVALID_RESULT : sqrt(radicand);
}
