module temperature_conversions;

const long SCALE = 1000000;
const long MAX_ABS_TEMPERATURE_MICRO = 1000000000000;
const double INVALID_RESULT = -1e300;
const usz MAX_INPUT_LENGTH = 3;

fn double temperature_conversions(long* values, usz length) @export("temperature_conversions") {
    if (values == null || length != 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long operation = values[0], micro = values[1];
    if (micro < -MAX_ABS_TEMPERATURE_MICRO || micro > MAX_ABS_TEMPERATURE_MICRO) return INVALID_RESULT;
    switch (operation) {
        case 0:
            if (micro % 5000000 != 0) return INVALID_RESULT;
            return (double)(9 * (micro / 5000000) + 32);
        case 1:
            if ((micro - 32000000) % 9000000 != 0) return INVALID_RESULT;
            return (double)(5 * ((micro - 32000000) / 9000000));
        case 2:
            if (micro % SCALE != 0) return INVALID_RESULT;
            return (double)(micro / SCALE) + 273.15;
        case 3:
            if ((micro - 273150000) % SCALE != 0) return INVALID_RESULT;
            return (double)((micro - 273150000) / SCALE);
        case 4:
            if ((micro - 273150000) % 5000000 != 0) return INVALID_RESULT;
            return (double)(9 * ((micro - 273150000) / 5000000) + 32);
        default: return INVALID_RESULT;
    }
}
