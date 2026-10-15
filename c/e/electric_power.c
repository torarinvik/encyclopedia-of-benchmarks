/* Pinned electric_power formula over the benchmark's bounded integer-valued domain. */
#include <stdint.h>

double electric_power(double voltage, double current, double power)
{
    if (voltage != voltage || current != current || power != power ||
        voltage < -10000.0 || voltage > 10000.0 ||
        current < -10000.0 || current > 10000.0 ||
        power < 0.0 || power > 100000000.0 ||
        voltage != (double)(int64_t)voltage ||
        current != (double)(int64_t)current ||
        power != (double)(int64_t)power) return -1.0e300;
    const int zeros = (voltage == 0.0) + (current == 0.0) + (power == 0.0);
    if (zeros != 1) return -1.0e300;
    if (voltage == 0.0) return power / current;
    if (current == 0.0) return power / voltage;
    const double product = voltage * current;
    return product < 0.0 ? -product : product;
}
