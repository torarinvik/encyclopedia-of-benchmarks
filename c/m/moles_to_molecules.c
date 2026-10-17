/* Convert bounded micro-moles to a formatted molecule count. */
#include <stddef.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_MOLES_MICRO INT64_C(2000000)
#define INVALID_RESULT (-1.0e300)

/* Round the exact binary64 value to five decimal significant digits using
 * nearest-even, as Python's `.4e` formatter does. The bounded positive result
 * has decimal exponent 17..24, which keeps these exact integer operations
 * within uint64_t.
 */
static double format_scientific_four(double value) {
    if (value == 0.0) return 0.0;

    int decimal_exponent = 0;
    double normalized = value;
    while (normalized >= 10.0) {
        normalized /= 10.0;
        ++decimal_exponent;
    }
    while (normalized < 1.0) {
        normalized *= 10.0;
        --decimal_exponent;
    }

    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    const uint64_t fraction = bits & ((UINT64_C(1) << 52u) - 1u);
    const int exponent_bits = (int)((bits >> 52u) & UINT64_C(0x7ff));
    const uint64_t significand = (UINT64_C(1) << 52u) | fraction;
    const int binary_exponent = exponent_bits - 1023 - 52;
    const int decimal_shift = decimal_exponent - 4;

    uint64_t denominator = 1u;
    for (int index = 0; index < decimal_shift; ++index) denominator *= 5u;
    const int binary_shift = binary_exponent - decimal_shift;
    uint64_t numerator = significand;
    if (binary_shift >= 0)
        numerator <<= (unsigned)binary_shift;
    else
        denominator <<= (unsigned)(-binary_shift);

    uint64_t rounded = numerator / denominator;
    const uint64_t remainder = numerator % denominator;
    const uint64_t twice_remainder = remainder * 2u;
    if (twice_remainder > denominator
        || (twice_remainder == denominator && (rounded & 1u) != 0u))
        ++rounded;

    /* Parsing the exact rounded decimal value models the source's final
     * format-then-parse conversion. The integer mantissa avoids relying on a
     * libc printf implementation for tie handling.
     */
    char formatted[64];
    const int length = snprintf(formatted, sizeof(formatted), "%" PRIu64 "e%+d",
                                rounded, decimal_shift);
    if (length < 0 || (size_t)length >= sizeof(formatted)) return INVALID_RESULT;

    char *end = NULL;
    const double parsed = strtod(formatted, &end);
    if (end != formatted + length) return INVALID_RESULT;
    return parsed;
}

double moles_to_molecules(const int64_t *values, size_t length) {
    if (values == NULL || length != 1) return INVALID_RESULT;

    const int64_t moles_micro = values[0];
    if (moles_micro < 0 || moles_micro > MAX_MOLES_MICRO)
        return INVALID_RESULT;

    const double moles = (double)moles_micro / 1000000.0;
    const double molecules = moles * 6.022e23;
    return format_scientific_four(molecules);
}
