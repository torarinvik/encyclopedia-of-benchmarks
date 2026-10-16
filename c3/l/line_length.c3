module line_length;

extern fn double sin(double value);
extern fn double sqrt(double value);

const double INVALID_RESULT = -1e300;
const long MAX_STEPS = 10000;

// Repeated-step polyline length for the source demo curve sin(10*x).
fn double line_length(double x_start, double x_end, double steps_value) @export("line_length") {
    if (x_start != x_start || x_end != x_end || steps_value != steps_value ||
        x_start < -10.0 || x_start > 10.0 || x_end < -10.0 || x_end > 10.0 ||
        x_start > x_end || steps_value < 1.0 || steps_value > (double)MAX_STEPS) {
        return INVALID_RESULT;
    }
    long steps = (long)steps_value;
    if ((double)steps != steps_value) return INVALID_RESULT;

    double x1 = x_start;
    double fx1 = sin(10.0 * x_start);
    double length = 0.0;
    for (long index = 0; index < steps; index++) {
        double x2 = (x_end - x_start) / (double)steps + x1;
        double fx2 = sin(10.0 * x2);
        double dx = x2 - x1;
        double dy = fx2 - fx1;
        length += sqrt(dx * dx + dy * dy);
        x1 = x2;
        fx1 = fx2;
    }
    return length;
}
