module sqrt_newton_raphson;

extern fn double trunc(double value);
const double INVALID_RESULT = -1.0e300;
const double MAX_INPUT = 2147483647.0;

fn double square_root_with_newton_raphson_method(double input) @export("square_root_with_newton_raphson_method") {
    if (input != input || input < 1.0 || input > MAX_INPUT || trunc(input) != input) return INVALID_RESULT;
    double guess = input;
    double root = 0.5 * (guess + input / guess);
    while (root - guess > 1e-7 || guess - root > 1e-7) {
        guess = root;
        root = 0.5 * (guess + input / guess);
    }
    return root;
}
