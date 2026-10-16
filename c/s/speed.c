#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_SPEED_MICRO INT64_C(1000000000000000)
#define MAX_ROUNDED_MILLI 9007199254740992.0

static const double to_kmh_factors[7] = {
    1.0, 3.6, 1.609344, 1.852, 1.09728, 1225.08, 1079252848.8
};
static const double from_kmh_factors[7] = {
    1.0, 0.277777778, 0.621371192, 0.539956803,
    0.911344415, 0.000816164, 9.265669311e-10
};

static double round_three_away(double scaled)
{
    if (scaled == 0.0) return scaled / 1000.0;
    const int negative = scaled < 0.0;
    const double magnitude = negative ? -scaled : scaled;
    uint64_t rounded_milli = (uint64_t)magnitude;
    if (magnitude - (double)rounded_milli >= 0.5) rounded_milli++;
    const double rounded = (double)rounded_milli / 1000.0;
    return negative ? -rounded : rounded;
}

double speed(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t speed_micro = values[0];
    const int64_t from_unit = values[1];
    const int64_t to_unit = values[2];
    if (speed_micro < -MAX_SPEED_MICRO || speed_micro > MAX_SPEED_MICRO ||
        from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6) return INVALID_RESULT;
    const double speed_value = (double)speed_micro / 1000000.0;
    const double kmh = speed_value * to_kmh_factors[from_unit];
    const double result = kmh * from_kmh_factors[to_unit];
    const double scaled = result * 1000.0;
    if (scaled > MAX_ROUNDED_MILLI || scaled < -MAX_ROUNDED_MILLI) return INVALID_RESULT;
    return round_three_away(scaled);
}
