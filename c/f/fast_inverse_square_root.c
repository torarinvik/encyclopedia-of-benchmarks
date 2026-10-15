#include <math.h>
#include <stdint.h>
#include <string.h>

#define MIN_VALUE 1e-6
#define MAX_VALUE 1e6

/* Match PHP pack('f') / unpack('l') through an IEEE-754 binary32 bit reinterpretation. */
double fast_inverse_square_root(double value)
{
    if (isnan(value) || value < MIN_VALUE || value > MAX_VALUE) return -1.0;
    const float seed_input = (float)value;
    int32_t bits;
    memcpy(&bits, &seed_input, sizeof(bits));
    bits = INT32_C(0x5f3759df) - (bits >> 1);
    float seed;
    memcpy(&seed, &bits, sizeof(seed));
    const double y = (double)seed;
    return y * (1.5 - 0.5 * value * y * y);
}
