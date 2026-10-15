module bisection_method;

const MAX_COORD_MILLI = 100000;
const MAX_TOLERANCE_MICRO = 1000000;
const ROOT_SCALE = 1000000.0;
const MAX_ITERATIONS = 64;

fn double evaluate(long equation, double x) {
    if (equation == 0) return x * x * x + 2.0 * x - 10.0;
    return x * x * x - 4.0 * x - 9.0;
}

// Return the rounded micro-unit root, -1 for invalid input, or -2 when not bracketed.
fn long bisection_method(long* input, usz length) @export("bisection_method") {
    if (input == null || length != 4) return -1;
    long equation = input[0], left_milli = input[1], right_milli = input[2], tolerance_micro = input[3];
    if (equation < 0 || equation > 1 || left_milli < -MAX_COORD_MILLI || left_milli > MAX_COORD_MILLI ||
        right_milli < -MAX_COORD_MILLI || right_milli > MAX_COORD_MILLI || left_milli >= right_milli ||
        tolerance_micro < 1 || tolerance_micro > MAX_TOLERANCE_MICRO) return -1;
    double left = (double)left_milli / 1000.0;
    double right = (double)right_milli / 1000.0;
    double f_left = evaluate(equation, left);
    double f_right = evaluate(equation, right);
    if (f_left == 0.0) return (long)(left * ROOT_SCALE + 0.5);
    if (f_right == 0.0) return (long)(right * ROOT_SCALE + 0.5);
    if ((f_left < 0.0) == (f_right < 0.0)) return -2;
    double tolerance = (double)tolerance_micro / ROOT_SCALE;
    for (int iteration = 0; iteration < MAX_ITERATIONS; iteration++) {
        double middle = left + (right - left) * 0.5;
        double f_middle = evaluate(equation, middle);
        if (f_middle == 0.0) return (long)(middle * ROOT_SCALE + 0.5);
        if ((f_left < 0.0) != (f_middle < 0.0)) {
            right = middle;
            f_right = f_middle;
        } else {
            left = middle;
            f_left = f_middle;
        }
        if (right - left <= tolerance) {
            double root = left + (right - left) * 0.5;
            return (long)(root * ROOT_SCALE + 0.5);
        }
    }
    return -2;
}
