module softplus;

extern fn double exp(double value);
extern fn double log(double value);

const double INVALID_RESULT = -1.0e300;

fn double softplus(double x) @export("softplus") {
    if (x != x || x < -100.0 || x > 100.0) return INVALID_RESULT;
    return log(1.0 + exp(x));
}
