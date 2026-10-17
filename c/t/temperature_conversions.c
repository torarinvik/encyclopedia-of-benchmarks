#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_ABS_TEMPERATURE_MICRO INT64_C(1000000000000)
#define INVALID_RESULT (-1.0e300)
#define MAX_INPUT_LENGTH 3

double temperature_conversions(const int64_t *values, size_t length) {
    if (values == NULL || length != 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t operation = values[0], micro = values[1];
    if (micro < -MAX_ABS_TEMPERATURE_MICRO || micro > MAX_ABS_TEMPERATURE_MICRO) return INVALID_RESULT;
    switch (operation) {
        case 0:
            if (micro % INT64_C(5000000) != 0) return INVALID_RESULT;
            return (double)(9 * (micro / INT64_C(5000000)) + 32);
        case 1:
            if ((micro - INT64_C(32000000)) % INT64_C(9000000) != 0) return INVALID_RESULT;
            return (double)(5 * ((micro - INT64_C(32000000)) / INT64_C(9000000)));
        case 2:
            if (micro % SCALE != 0) return INVALID_RESULT;
            return (double)(micro / SCALE) + 273.15;
        case 3:
            if ((micro - INT64_C(273150000)) % SCALE != 0) return INVALID_RESULT;
            return (double)((micro - INT64_C(273150000)) / SCALE);
        case 4:
            if ((micro - INT64_C(273150000)) % INT64_C(5000000) != 0) return INVALID_RESULT;
            return (double)(9 * ((micro - INT64_C(273150000)) / INT64_C(5000000)) + 32);
        default: return INVALID_RESULT;
    }
}
