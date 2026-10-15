module real_and_reactive_power;

const double INVALID_RESULT = -1.0e300;
extern fn double pow(double base, double exponent);
extern fn double sqrt(double value);

fn double real_and_reactive_power(long* values, usz length) @export("real_and_reactive_power") {
    if (values == null || length != 3) return INVALID_RESULT;
    long operation = values[0];
    long apparent_power = values[1];
    long factor_units = values[2];
    if ((operation != 0 && operation != 1) || apparent_power < -1000000000 ||
        apparent_power > 1000000000 || factor_units < -10000 || factor_units > 10000)
        return INVALID_RESULT;
    double power_factor = (double)factor_units / 10000.0;
    if (operation == 0) return (double)apparent_power * power_factor;
    return (double)apparent_power * sqrt(1.0 - pow(power_factor, 2.0));
}
