module snell_law;

extern fn double sin(double value);
extern fn double asin(double value);
extern fn double fabs(double value);

const double INVALID_RESULT = -1.0e300;
const double HALF_PI = 1.5707963267948966;

fn double snell_law(double n1, double n2, double theta1) @export("snell_law") {
    if (n1 != n1 || n2 != n2 || theta1 != theta1 ||
        n1 < 0.5 || n1 > 2.5 || n2 < 0.5 || n2 > 2.5 ||
        theta1 < -HALF_PI || theta1 > HALF_PI) return INVALID_RESULT;
    double ratio = n1 / n2;
    double sin_theta2 = ratio * sin(theta1);
    if (fabs(sin_theta2) > 1.0) return INVALID_RESULT;
    return asin(sin_theta2);
}
