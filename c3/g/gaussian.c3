module gaussian;

extern fn double sqrt(double value);
extern fn double exp(double value);

const double INVALID_RESULT = -1.0e300;
const double PI = 3.14159265358979323846264338327950288;

fn double gaussian(long* values, usz length) @export("gaussian") {
    if (values == null || length != 3) return INVALID_RESULT;
    long x = values[0];
    long mu = values[1];
    long sigma = values[2];
    if (x < -100 || x > 100 || mu < -100 || mu > 100 || sigma < 1 || sigma > 100) return INVALID_RESULT;
    long difference = x - mu;
    long sigma_squared = sigma * sigma;
    double normalization = 1.0 / sqrt(2.0 * PI * (double)sigma_squared);
    double exponent = -(double)(difference * difference) / (double)(2 * sigma_squared);
    return normalization * exp(exponent);
}
