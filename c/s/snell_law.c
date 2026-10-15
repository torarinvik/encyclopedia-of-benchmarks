#include <math.h>

#define INVALID_RESULT (-1.0e300)

double snell_law(double n1, double n2, double theta1)
{
    if (n1 != n1 || n2 != n2 || theta1 != theta1 ||
        n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 ||
        theta1 < -1.5707963267948966 || theta1 > 1.5707963267948966) {
        return INVALID_RESULT;
    }
    const double ratio = n1 / n2;
    const double sin_theta2 = ratio * sin(theta1);
    if (fabs(sin_theta2) > 1.0) return INVALID_RESULT;
    return asin(sin_theta2);
}
