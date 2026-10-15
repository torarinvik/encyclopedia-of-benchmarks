module leaky_relu;

const double INVALID_RESULT = -1.0e300;
const double MAX_INPUT = 1000000.0;

fn double leaky_relu(double x, double alpha) @export("leaky_relu") {
    if (x != x || alpha != alpha || x < -MAX_INPUT || x > MAX_INPUT || alpha < -MAX_INPUT || alpha > MAX_INPUT) {
        return INVALID_RESULT;
    }
    return x < 0.0 ? x * alpha : x;
}
