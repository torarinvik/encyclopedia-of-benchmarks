/* Ohm's law over a bounded integer-valued input domain. */
#include <math.h>

double ohms_law(double voltage, double current, double resistance)
{
    if (!isfinite(voltage) || !isfinite(current) || !isfinite(resistance) ||
        voltage < -1000.0 || voltage > 1000.0 || current < -1000.0 || current > 1000.0 ||
        resistance < 0.0 || resistance > 1000.0 ||
        voltage != trunc(voltage) || current != trunc(current) || resistance != trunc(resistance)) return -1e300;
    const int zeros = (voltage == 0.0) + (current == 0.0) + (resistance == 0.0);
    if (zeros != 1) return -1e300;
    if (voltage == 0.0) return current * resistance;
    if (current == 0.0) return voltage / resistance;
    return voltage / current;
}
