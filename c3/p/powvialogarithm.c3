module powvialogarithm;

const double INVALID_RESULT = -1.0e300;
extern fn double log(double value);
extern fn double exp(double value);
extern fn double fabs(double value);
extern fn double trunc(double value);
extern fn double round(double value);

fn double powvialogarithm(double base, double exponent) @export("powvialogarithm") {
    if (!(base >= -4.0 && base <= 4.0 && exponent >= -8.0 && exponent <= 8.0) ||
        trunc(base) != base || trunc(exponent) != exponent ||
        (base == 0.0 && exponent <= 0.0) ||
        (base == 2.0 && exponent == -1.0) || (base == -2.0 && exponent == -1.0)) {
        return INVALID_RESULT;
    }

    double sign = 1.0;
    int power = (int)exponent;
    if (base < 0.0 && (power & 1) != 0) sign = -1.0;
    double logarithm = log(fabs(base));
    double exponential = exp(exponent * logarithm);
    double result = exponential * sign;
    return round(result);
}
