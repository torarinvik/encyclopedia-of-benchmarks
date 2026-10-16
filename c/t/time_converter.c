/* Port of the pinned Java TimeConverter conversion factors and rounding. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 4
#define MAX_TIME_MICRO INT64_C(1000000000)
#define SCALE INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

static double seconds_per_unit(int64_t unit)
{
    switch (unit) {
        case 0: return 1.0;
        case 1: return 60.0;
        case 2: return 3600.0;
        case 3: return 86400.0;
        case 4: return 604800.0;
        case 5: return 2629800.0;
        case 6: return 31557600.0;
        default: return 0.0;
    }
}

double time_converter(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    int64_t time_micro = values[0], from_unit = values[1], to_unit = values[2];
    if (time_micro < 0 || time_micro > MAX_TIME_MICRO || from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6)
        return INVALID_RESULT;
    double time_value = (double)time_micro / (double)SCALE;
    double seconds_value = time_value * seconds_per_unit(from_unit);
    double converted = seconds_value / seconds_per_unit(to_unit);
    int64_t rounded = (int64_t)(converted * 1000.0 + 0.5);
    return (double)rounded / 1000.0;
}
