module sin_degrees;

extern fn double floor(double value);
extern fn double pow(double base, double exponent);
extern fn double round(double value);

fn double sin_degrees(double angle) @export("sin_degrees") {
    if (!(angle >= -1000000.0 && angle <= 1000000.0)) return -1.0;

    angle = angle - floor(angle / 360.0) * 360.0;
    double radians = angle * (3.141592653589793 / 180.0);
    double result = radians;
    double sign = -1.0;
    long exponent = 3;
    for (long term = 0; term < 18; term++) {
        double factorial = 1.0;
        for (long factor = 2; factor <= exponent; factor++) factorial *= (double)factor;
        result += sign * pow(radians, (double)exponent) / factorial;
        sign = -sign;
        exponent += 2;
    }
    return round(result * 10000000000.0) / 10000000000.0;
}
