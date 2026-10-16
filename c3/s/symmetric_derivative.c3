module symmetric_derivative;

extern fn double sin(double value);
extern fn double exp(double value);

const long MIN_X_NANOUNITS = -6300000000;
const long MAX_X_NANOUNITS = 6300000000;
const double DEFAULT_STEP = 1.0e-10;
const double INVALID_RESULT = -1.0e300;

fn double symmetric_derivative(long* values, usz length) @export("symmetric_derivative") {
    if (values == null || length != 2) return INVALID_RESULT;
    long function_id = values[0], x_nanounits = values[1];
    if ((function_id != 0 && function_id != 1) ||
        x_nanounits < MIN_X_NANOUNITS || x_nanounits > MAX_X_NANOUNITS) return INVALID_RESULT;

    double x = (double)x_nanounits / 1000000000.0;
    double upper = function_id == 0 ? sin(x + DEFAULT_STEP) : exp(x + DEFAULT_STEP);
    double lower = function_id == 0 ? sin(x - DEFAULT_STEP) : exp(x - DEFAULT_STEP);
    return (upper - lower) / (2.0 * DEFAULT_STEP);
}
