module cartesian_to_polar;

extern fn double sqrt(double value);
extern fn double atan2(double y, double x);

// Return radius for component 0 and the atan2 angle for component 1.
fn double cartesian_to_polar(double x, double y, double component) @export("cartesian_to_polar") {
    if (x != x || y != y || (component != 0.0 && component != 1.0) ||
        x < -1000000.0 || x > 1000000.0 || y < -1000000.0 || y > 1000000.0) return -1.0e300;
    if (component == 0.0) return sqrt(x * x + y * y);
    if (x == 0.0 && y == 0.0) return 0.0;
    return atan2(y, x);
}
