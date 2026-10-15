module sin_radians;

extern fn double floor(double value);
extern fn double fabs(double value);

fn double sin_radians(double radians) @export("sin_radians")
{
    if (!(radians >= -1000000.0 && radians <= 1000000.0)) return -1.0;
    double x = (3.141592653589793 / 2.0) - radians;
    double tp = 1.0 / (2.0 * 3.141592653589793);
    x *= tp;
    x -= 0.25 + floor(x + 0.25);
    x *= 16.0 * (fabs(x) - 0.5);
    x += 0.225 * x * (fabs(x) - 1.0);
    return x;
}
