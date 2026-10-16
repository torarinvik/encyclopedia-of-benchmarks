/* Six direct conversions from the pinned Java TemperatureConverter source. */
#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_ABS_TEMPERATURE_MICRO INT64_C(1000000000000)
#define MAX_INPUT_LENGTH 3
#define INVALID_RESULT (-1.0e300)

double temperature_converter(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t operation = values[0];
    const int64_t temperature_micro = values[1];
    if (temperature_micro < -MAX_ABS_TEMPERATURE_MICRO || temperature_micro > MAX_ABS_TEMPERATURE_MICRO)
        return INVALID_RESULT;
    const double temperature = (double)temperature_micro / (double)SCALE;
    switch (operation) {
        case 0: return temperature * 9.0 / 5.0 + 32.0;
        case 1: return temperature + 273.15;
        case 2: return (temperature - 32.0) * 5.0 / 9.0;
        case 3: return (temperature - 32.0) * 5.0 / 9.0 + 273.15;
        case 4: return temperature - 273.15;
        case 5: return (temperature - 273.15) * 9.0 / 5.0 + 32.0;
        default: return INVALID_RESULT;
    }
}
