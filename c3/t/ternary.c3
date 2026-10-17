module ternary;

extern fn double fabs(double value);

const usz MAX_INPUT_LENGTH = 6;
const double INVALID_RESULT = -1.0e300;

fn double objective(long operation, double x) {
    double delta = operation == 0 ? x - 1.0 : x + 1.0;
    double square = delta * delta;
    return operation == 0 ? -square : square;
}

fn double ternary_search(long operation, double a, double b, double epsilon,
                         long frame, long max_calls) {
    if (fabs(a - b) <= epsilon) return objective(operation, (a + b) / 2.0);

    double left = (2.0 * a + b) / 3.0;
    double right = (a + 2.0 * b) / 3.0;
    double left_value = objective(operation, left);
    double right_value = objective(operation, right);
    bool take_left = operation == 0 ? left_value < right_value : left_value > right_value;
    if (frame >= max_calls) return INVALID_RESULT;
    if (take_left) return ternary_search(operation, left, b, epsilon, frame + 1, max_calls);
    return ternary_search(operation, a, right, epsilon, frame + 1, max_calls);
}

fn double ternary(long* input, usz length) @export("ternary") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long operation = input[0], a_milli = input[1], b_milli = input[2];
    long epsilon_micro = input[3], max_calls = input[4];
    if (length != 5 || (operation != 0 && operation != 1) ||
        a_milli < -1000000 || a_milli > b_milli || b_milli > 1000000 ||
        epsilon_micro < 1 || epsilon_micro > 1000000 || max_calls < 1 || max_calls > 64) return INVALID_RESULT;

    return ternary_search(operation, (double)a_milli / 1000.0, (double)b_milli / 1000.0,
                          (double)epsilon_micro / 1000000.0, 1, max_calls);
}
