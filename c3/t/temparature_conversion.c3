module temparature_conversion;

extern fn double floor(double value);

const long MAX_ABS_TEMPERATURE_MICRO = 1000000000000;
const usz MAX_INPUT_LENGTH = 4;
const double INVALID_RESULT = -1.0e300;

fn double round_nearest_ties_even(double value) {
    double lower = floor(value);
    double fraction = value - lower;
    if (fraction < 0.5) return lower;
    if (fraction > 0.5) return lower + 1.0;
    long integer = (long)lower;
    return integer % 2 == 0 ? lower : lower + 1.0;
}

fn double round_digits(double value, long digits) {
    double scale = 1.0;
    long magnitude = digits < 0 ? -digits : digits;
    for (long index = 0; index < magnitude; index++) scale *= 10.0;
    double scaled = digits >= 0 ? value * scale : value / scale;
    double rounded = round_nearest_ties_even(scaled);
    return digits >= 0 ? rounded / scale : rounded * scale;
}

fn double temparature_conversion(long* input, usz length) @export("temparature_conversion") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long operation = input[0];
    long temperature_micro = input[1];
    long digits = input[2];
    if (length != 3 || operation < 0 || operation > 5
        || temperature_micro < -MAX_ABS_TEMPERATURE_MICRO || temperature_micro > MAX_ABS_TEMPERATURE_MICRO
        || digits < -6 || digits > 6) return INVALID_RESULT;

    double temperature = (double)temperature_micro / 1000000.0;
    double result;
    if (operation == 0) result = temperature * 1.8 + 32.0;
    else if (operation == 1) result = temperature + 273.15;
    else if (operation == 2) result = (temperature - 32.0) * 5.0 / 9.0;
    else if (operation == 3) result = (temperature - 32.0) * 5.0 / 9.0 + 273.15;
    else if (operation == 4) result = temperature - 273.15;
    else result = (temperature - 273.15) * 1.8 + 32.0;
    return round_digits(result, digits);
}
