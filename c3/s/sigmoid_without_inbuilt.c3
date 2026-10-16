module sigmoid_without_inbuilt;

extern fn double exp(double value);
const double INVALID_RESULT = -1.0e300;

fn double sigmoid_without_inbuilt(double x, double slope) @export("sigmoid_without_inbuilt") {
    if (x != x || slope != slope || x < -10.0 || x > 10.0 ||
        slope < -10.0 || slope > 10.0) return INVALID_RESULT;
    return 1.0 / (1.0 + exp(-slope * x));
}

