module relu;

extern fn double trunc(double value);
const double INVALID_RESULT = -1.0e300;
const double MAX_INPUT = 16777216.0;

fn double relu(double x) @export("relu") {
    if (x != x || x < -MAX_INPUT || x > MAX_INPUT || trunc(x) != x) return INVALID_RESULT;
    return x > 0.0 ? x : 0.0;
}
