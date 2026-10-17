#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { MASS_TO_MOLES_INPUT_LENGTH = 2 };
static const double MASS_TO_MOLES_INVALID = -1.0e300;

/* Round the exact binary64 quotient to the nearest hundredth, ties to even.
 * The bounded mass/molar-mass domain keeps the binary exponent in [-62, -43],
 * so the integer numerator and power-of-two denominator fit in uint64_t.
 */
static double round_binary64_to_hundredth(double value) {
    if (value == 0.0) return 0.0;

    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    const unsigned exponent_field = (unsigned)((bits >> 52) & 0x7ffu);
    const uint64_t significand = (bits & UINT64_C(0x000fffffffffffff)) |
                                 UINT64_C(0x0010000000000000);
    const int binary_power = (int)exponent_field - 1023 - 52;
    if (binary_power >= 0 || -binary_power >= 64) return MASS_TO_MOLES_INVALID;

    const uint64_t numerator = significand * UINT64_C(100);
    const uint64_t denominator = UINT64_C(1) << (unsigned)(-binary_power);
    uint64_t rounded_cents = numerator / denominator;
    const uint64_t remainder = numerator % denominator;
    const uint64_t twice_remainder = remainder * UINT64_C(2);
    if (twice_remainder > denominator ||
        (twice_remainder == denominator && (rounded_cents & UINT64_C(1)) != 0)) {
        ++rounded_cents;
    }
    return (double)rounded_cents / 100.0;
}

double mass_to_moles(const int64_t *input, size_t length) {
    if (input == NULL || length != MASS_TO_MOLES_INPUT_LENGTH) {
        return MASS_TO_MOLES_INVALID;
    }

    const int64_t mass = input[0];
    const int64_t molar_mass = input[1];
    if (mass < 0 || mass > 1000 || molar_mass < 1 || molar_mass > 1000) {
        return MASS_TO_MOLES_INVALID;
    }

    const double quotient = (double)mass / (double)molar_mass;
    return round_binary64_to_hundredth(quotient);
}
