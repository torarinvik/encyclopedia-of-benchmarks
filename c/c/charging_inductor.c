#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double round_three_python(double value)
{
    if (value == 0.0) return value;
    const int negative = value < 0.0;
    double normalized = negative ? -value : value;
    int exponent = 0;
    while (normalized >= 1.0) { normalized *= 0.5; exponent++; }
    while (normalized < 0.5) { normalized *= 2.0; exponent--; }
    const uint64_t significand = (uint64_t)(normalized * 9007199254740992.0);
    const uint64_t numerator = significand * 1000;
    const int shift = 53 - exponent;
    uint64_t milliunits = 0;
    if (shift < 0) milliunits = numerator << (unsigned)(-shift);
    else if (shift == 0) milliunits = numerator;
    else if (shift < 64) {
        const uint64_t denominator = UINT64_C(1) << (unsigned)shift;
        milliunits = numerator >> (unsigned)shift;
        const uint64_t remainder = numerator & (denominator - 1);
        const uint64_t half = denominator >> 1;
        if (remainder > half || (remainder == half && (milliunits & 1) != 0)) milliunits++;
    }
    const double rounded = (double)milliunits / 1000.0;
    return negative ? -rounded : rounded;
}

double charging_inductor(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t voltage_micro = values[0];
    const int64_t resistance_micro = values[1];
    const int64_t inductance_micro = values[2];
    const int64_t time_micro = values[3];
    if (voltage_micro < 1 || voltage_micro > INT64_C(1000000000000) ||
        resistance_micro < 10000 || resistance_micro > INT64_C(1000000000000000) ||
        inductance_micro < 1 || inductance_micro > INT64_C(1000000000000) ||
        time_micro < -INT64_C(1000000000000) || time_micro > INT64_C(1000000000000))
        return INVALID_RESULT;
    const double source_voltage = (double)voltage_micro / 1000000.0;
    const double resistance = (double)resistance_micro / 1000000.0;
    const double inductance = (double)inductance_micro / 1000000.0;
    const double time_sec = (double)time_micro / 1000000.0;
    const double exponent = (-time_sec * resistance) / inductance;
    if (exponent > 10.0) return INVALID_RESULT;
    return round_three_python(source_voltage / resistance * (1.0 - exp(exponent)));
}
