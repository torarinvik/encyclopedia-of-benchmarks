module time_converter;

const long SCALE = 1000000;
const long MAX_TIME_MICRO = 1000000000;
const usz MAX_INPUT_LENGTH = 4;
const double INVALID_RESULT = -1.0e300;

fn double seconds_per_unit(long unit) {
    if (unit == 0) return 1.0;
    if (unit == 1) return 60.0;
    if (unit == 2) return 3600.0;
    if (unit == 3) return 86400.0;
    if (unit == 4) return 604800.0;
    if (unit == 5) return 2629800.0;
    if (unit == 6) return 31557600.0;
    return 0.0;
}

fn double time_converter(long* values, usz length) @export("time_converter") {
    if (values == null || length != 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long time_micro = values[0], from_unit = values[1], to_unit = values[2];
    if (time_micro < 0 || time_micro > MAX_TIME_MICRO || from_unit < 0 || from_unit > 6 || to_unit < 0 || to_unit > 6)
        return INVALID_RESULT;
    double time_value = (double)time_micro / (double)SCALE;
    double seconds_value = time_value * seconds_per_unit(from_unit);
    double converted = seconds_value / seconds_per_unit(to_unit);
    long rounded = (long)(converted * 1000.0 + 0.5);
    return (double)rounded / 1000.0;
}
