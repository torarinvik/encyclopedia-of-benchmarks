module trig_functions;

const double PI = 3.14159265358979323846;

fn bool finite_value(double value) {
    return value == value && value <= 1.7976931348623157e308 && value >= -1.7976931348623157e308;
}

fn double nan_value() {
    double zero = 0.0;
    return zero / zero;
}

fn double abs_value(double value) { return value < 0.0 ? -value : value; }

fn double rounded_six(double value) {
    double scaled = abs_value(value) * 1000000.0;
    long rounded = (long)(scaled + 0.5);
    return (value < 0.0 ? -(double)rounded : (double)rounded) / 1000000.0;
}

fn double integer_power(double value, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) result *= value;
    return result;
}

fn double factorial_double(int n) {
    double result = 1.0;
    for (int i = 2; i <= n; i++) result *= (double)i;
    return result;
}

fn double trig_series(double value, double tolerance, int kind) {
    double period = 2.0 * PI;
    while (value >= period) value -= period;
    while (value <= -period) value += period;
    double result = 0.0, previous = 1.0;
    int step = 0;
    while (abs_value(previous - result) > tolerance) {
        previous = result;
        int power = 2 * step + kind;
        double term = integer_power(value, power) / factorial_double(power);
        result += step % 2 == 0 ? term : -term;
        step++;
    }
    return rounded_six(result);
}

fn long trig_functions(double* input, usz length, double* output, usz capacity) @export("trig_functions") {
    if (input == null || length != 3) return -1;
    double selector_value = input[0], x = input[1], tolerance = input[2];
    if (!finite_value(selector_value) || selector_value < 0.0 || selector_value > 7.0) return -1;
    long selector = (long)selector_value;
    if (selector_value != (double)selector) return -1;
    if (!finite_value(tolerance) || tolerance < 1e-9 || tolerance > 1e-2) return -1;
    if (finite_value(x) && (x < -10000.0 || x > 10000.0)) return -1;
    if (output == null || capacity < 1) return -2;
    if (!finite_value(x)) { output[0] = nan_value(); return 1; }
    if (selector == 2 || selector == 3 || selector == 6 || selector == 7) x = x * PI / 180.0;

    double result = 0.0;
    if (selector == 0 || selector == 2) result = trig_series(x, tolerance, 1);
    else if (selector == 1 || selector == 3) result = trig_series(x, tolerance, 0);
    else if (selector == 4 || selector == 6) {
        double denominator = trig_series(x, tolerance, 0);
        result = denominator == 0.0 ? nan_value() : trig_series(x, tolerance, 1) / denominator;
    } else {
        double denominator = trig_series(x, tolerance, 1);
        result = denominator == 0.0 ? nan_value() : trig_series(x, tolerance, 0) / denominator;
    }
    output[0] = result;
    return 1;
}
