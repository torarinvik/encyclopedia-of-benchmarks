#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN

static double convert_temperature(int64_t operation, double value) {
    switch (operation) {
        case 0: return (value * 9.0) / 5.0 + 32.0;
        case 1: return value + 273.15;
        case 2: return (value * 9.0) / 5.0 + 491.67;
        case 3: return ((value - 32.0) * 5.0) / 9.0;
        case 4: return ((value - 32.0) * 5.0) / 9.0 + 273.15;
        case 5: return value + 459.67;
        case 6: return value - 273.15;
        case 7: return ((value - 273.15) * 9.0) / 5.0 + 32.0;
        case 8: return (value * 9.0) / 5.0;
        case 9: return ((value - 491.67) * 5.0) / 9.0;
        case 10: return value - 459.67;
        case 11: return (value * 5.0) / 9.0;
        case 12: return value * 1.25;
        case 13: return value * 2.25 + 32.0;
        case 14: return value * 1.25 + 273.15;
        case 15: return value * 2.25 + 32.0 + 459.67;
        default: return 0.0;
    }
}

int64_t temperature_conversion(const int64_t *values, size_t length) {
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t operation = values[0];
    const int64_t temperature = values[1];
    if (operation < 0 || operation > 15 || temperature < -1000000 || temperature > 1000000) return INVALID_RESULT;
    return (int64_t)floor(convert_temperature(operation, (double)temperature) + 0.5);
}
