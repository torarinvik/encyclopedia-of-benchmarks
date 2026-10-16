module temperature_converter;

const long SCALE = 1000000;
const long MAX_ABS_TEMPERATURE_MICRO = 1000000000000;
const usz MAX_INPUT_LENGTH = 3;
const double INVALID_RESULT = -1.0e300;

fn double temperature_converter(long* values, usz length) @export("temperature_converter") {
    if (values == null || length != 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long operation = values[0];
    long temperature_micro = values[1];
    if (temperature_micro < -MAX_ABS_TEMPERATURE_MICRO || temperature_micro > MAX_ABS_TEMPERATURE_MICRO) return INVALID_RESULT;
    double temperature = (double)temperature_micro / (double)SCALE;
    if (operation == 0) return temperature * 9.0 / 5.0 + 32.0;
    if (operation == 1) return temperature + 273.15;
    if (operation == 2) return (temperature - 32.0) * 5.0 / 9.0;
    if (operation == 3) return (temperature - 32.0) * 5.0 / 9.0 + 273.15;
    if (operation == 4) return temperature - 273.15;
    if (operation == 5) return (temperature - 273.15) * 9.0 / 5.0 + 32.0;
    return INVALID_RESULT;
}
