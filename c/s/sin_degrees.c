#include <math.h>

double sin_degrees(double angle)
{
    if (!(angle >= -1000000.0 && angle <= 1000000.0)) return -1.0;

    angle = angle - floor(angle / 360.0) * 360.0;
    const double radians = angle * (3.141592653589793 / 180.0);
    double result = radians;
    double sign = -1.0;
    int exponent = 3;
    for (int term = 0; term < 18; ++term) {
        double factorial = 1.0;
        for (int factor = 2; factor <= exponent; ++factor) factorial *= (double)factor;
        result += sign * pow(radians, (double)exponent) / factorial;
        sign = -sign;
        exponent += 2;
    }
    return round(result * 10000000000.0) / 10000000000.0;
}
