#include <math.h>
#include <stdint.h>

int64_t fibonacci_number_golden_ration(int64_t input)
{
    if (input < 0 || input > 70) return -1;
    if (input <= 1) return input;

    const double sqrt5 = sqrt(5.0);
    const double phi = (1.0 + sqrt5) / 2.0;
    const double psi = (1.0 - sqrt5) / 2.0;
    const double result = (pow(phi, (double)input) - pow(psi, (double)input)) / sqrt5;
    /* For this nonnegative range, Java Math.round(x) is floor(x + 0.5). */
    return (int64_t)floor(result + 0.5);
}
