/* Match the pinned MATLAB to_polar angle formula in degrees. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.141592653589793238462643383279502884

double to_polar_angle_degrees(double x, double y)
{
    if (x != x || y != y || x < -1000000.0 || x > 1000000.0 ||
        y < -1000000.0 || y > 1000000.0 || (x == 0.0 && y == 0.0)) {
        return INVALID_RESULT;
    }
    double theta;
    if (x >= 0.0) theta = atan(y / x);
    else theta = atan(y / x) + PI;
    return theta * (180.0 / PI);
}
