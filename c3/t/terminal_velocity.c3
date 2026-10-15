module terminal_velocity;

extern fn double sqrt(double value);

const double INVALID_RESULT = -1.0e300;

fn double terminal_velocity(long* values, usz length) @export("terminal_velocity") {
    if (values == null || length != 4) return INVALID_RESULT;
    long mass = values[0];
    long density = values[1];
    long area = values[2];
    long drag_coefficient = values[3];
    if (mass < 1 || mass > 1000 || density < 1 || density > 1000 || area < 1 || area > 1000 ||
        drag_coefficient < 1 || drag_coefficient > 1000)
        return INVALID_RESULT;
    double numerator = (2.0 * (double)mass) * 9.80665;
    double denominator = ((double)density * (double)area) * (double)drag_coefficient;
    return sqrt(numerator / denominator);
}
