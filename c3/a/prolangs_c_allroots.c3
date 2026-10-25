module prolangs_c_allroots;

extern fn double sqrt(double value);

const REQUIRED_BYTES: usz = 24;
const NEWTON_EPSILON: double = 5.0e-6;
const MAX_NEWTON_ITERATIONS: int = 40;

fn double absolute_value(double value) { return value < 0.0 ? -value : value; }

fn double horner_value_and_derivative(int degree, double* coefficients, double x, double* derivative) {
    double value = coefficients[degree];
    double slope = value;
    for (int j = degree - 1; j >= 1; j--) {
        value = x * value + coefficients[j];
        slope = x * slope + value;
    }
    value = x * value + coefficients[0];
    derivative[0] = slope;
    return value;
}

fn double newton_root(int degree, double* coefficients, double lower, double upper) {
    if (upper < lower) { double temporary = lower; lower = upper; upper = temporary; }
    double previous = lower;
    double current = (lower + upper) / 2.0;
    int iterations = 0;
    while (absolute_value(current - previous) / absolute_value(current) > NEWTON_EPSILON &&
           iterations <= MAX_NEWTON_ITERATIONS) {
        previous = current;
        double derivative = 0.0;
        double value = horner_value_and_derivative(degree, coefficients, current, &derivative);
        current = current - value / derivative;
        iterations++;
    }
    return current;
}

fn void store_f64_le(char* output, usz offset, double value) {
    ulong bits = @bitcast(ulong, value);
    for (usz i = 0; i < 8; i++) {
        output[offset + i] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn void solve(char* output) {
    double[4] original = {4.0, -4.0, -1.0, 1.0};
    double[4] coefficients = original;
    double upper = 0.0;
    for (int i = 0; i <= 3; i++) upper += absolute_value(coefficients[i]);
    upper /= absolute_value(coefficients[3]);
    double lower = -upper - 1.0;

    double first_root = newton_root(3, &coefficients[0], lower, upper);
    double[3] deflated = {};
    deflated[2] = coefficients[3];
    for (int i = 1; i >= 0; i--) deflated[i] = deflated[i + 1] * first_root + coefficients[i + 1];

    double discriminant = deflated[1] * deflated[1] - 4.0 * deflated[2] * deflated[0];
    double plus_root = (-deflated[1] + sqrt(discriminant)) / (2.0 * deflated[2]);
    double minus_root = (-deflated[1] - sqrt(discriminant)) / (2.0 * deflated[2]);
    double refined_plus = newton_root(3, &original[0], plus_root - 0.5, plus_root + 0.5);
    double refined_minus = newton_root(3, &original[0], minus_root - 0.5, minus_root + 0.5);
    store_f64_le(output, 0, first_root);
    store_f64_le(output, 8, refined_plus);
    store_f64_le(output, 16, refined_minus);
}

long prolangs_c_allroots(long* values, usz length, char* output, usz output_capacity)
    @export("prolangs_c_allroots") {
    if (values == null || length != 4 || values[0] != 4 || values[1] != -4 ||
        values[2] != -1 || values[3] != 1) return -1;
    if (output == null || output_capacity < REQUIRED_BYTES) return -2;
    char[REQUIRED_BYTES] staged;
    solve(&staged[0]);
    for (usz i = 0; i < REQUIRED_BYTES; i++) output[i] = staged[i];
    return (long)REQUIRED_BYTES;
}
