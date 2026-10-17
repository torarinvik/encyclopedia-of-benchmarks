#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_ABS_TEMPERATURE_MICRO INT64_C(1000000000000)
#define MAX_INPUT_LENGTH ((size_t)4)
#define INVALID_RESULT (-1.0e300)

static double round_nearest_ties_even(double value)
{
    const double lower = floor(value);
    const double fraction = value - lower;
    if (fraction < 0.5) return lower;
    if (fraction > 0.5) return lower + 1.0;
    const int64_t integer = (int64_t)lower;
    return integer % 2 == 0 ? lower : lower + 1.0;
}

static double round_digits(double value, int64_t digits)
{
    double scale = 1.0;
    const int64_t magnitude = digits < 0 ? -digits : digits;
    for (int64_t index = 0; index < magnitude; ++index) scale *= 10.0;
    const double scaled = digits >= 0 ? value * scale : value / scale;
    const double rounded = round_nearest_ties_even(scaled);
    return digits >= 0 ? rounded / scale : rounded * scale;
}

double temparature_conversion(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t operation = input[0];
    const int64_t temperature_micro = input[1];
    const int64_t digits = input[2];
    if (length != 3 || operation < 0 || operation > 5
            || temperature_micro < -MAX_ABS_TEMPERATURE_MICRO
            || temperature_micro > MAX_ABS_TEMPERATURE_MICRO
            || digits < -6 || digits > 6) return INVALID_RESULT;

    const double temperature = (double)temperature_micro / 1000000.0;
    double result;
    switch (operation) {
        case 0: result = temperature * 1.8 + 32.0; break;
        case 1: result = temperature + 273.15; break;
        case 2: result = (temperature - 32.0) * 5.0 / 9.0; break;
        case 3: result = (temperature - 32.0) * 5.0 / 9.0 + 273.15; break;
        case 4: result = temperature - 273.15; break;
        case 5: result = (temperature - 273.15) * 1.8 + 32.0; break;
        default: return INVALID_RESULT;
    }
    return round_digits(result, digits);
}
