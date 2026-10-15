module bisection_2;

const double INVALID_RESULT = -1.0e300;
const long MAX_ENDPOINT_MILLI = 100000;

fn double equation(double x) { return 10.0 - x * x; }

fn double bisection_2(long* input, usz length) @export("bisection_2") {
    if (input == null || length != 2) return INVALID_RESULT;
    long left_milli = input[0], right_milli = input[1];
    if (left_milli < -MAX_ENDPOINT_MILLI || left_milli > MAX_ENDPOINT_MILLI
        || right_milli < -MAX_ENDPOINT_MILLI || right_milli > MAX_ENDPOINT_MILLI
        || left_milli >= right_milli) return INVALID_RESULT;
    double a = (double)left_milli / 1000.0;
    double b = (double)right_milli / 1000.0;
    if (equation(a) * equation(b) >= 0.0) return INVALID_RESULT;
    double c = a;
    while ((b - a) >= 0.01) {
        c = (a + b) / 2.0;
        if (equation(c) == 0.0) break;
        if (equation(c) * equation(a) < 0.0) b = c;
        else a = c;
    }
    return c;
}
