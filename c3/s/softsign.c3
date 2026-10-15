module softsign;

extern fn double fabs(double value);

const double INVALID_RESULT = -1.0e300;

fn double softsign(double x) @export("softsign") {
    if (x != x || x < -1.0e100 || x > 1.0e100) return INVALID_RESULT;
    return x / (1.0 + fabs(x));
}
