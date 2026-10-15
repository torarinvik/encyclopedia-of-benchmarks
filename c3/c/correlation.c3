module correlation;

extern fn double sqrt(double value);

const double INVALID_RESULT = -1.0e300;
const double DELTA = 1.0e-9;
const long MAX_N = 128;

fn double correlation(long* values, usz length) @export("correlation") {
    if (values == null || length < 3) return INVALID_RESULT;
    long n_value = values[0];
    if (n_value < 1 || n_value > MAX_N || length != 1 + 2 * (usz)n_value) return INVALID_RESULT;
    usz n = (usz)n_value;
    double exy = 0.0, ex = 0.0, exx = 0.0, ey = 0.0, eyy = 0.0;
    for (usz i = 0; i < n; i++) {
        long xi = values[1 + i];
        long yi = values[1 + n + i];
        if (xi < -1000 || xi > 1000 || yi < -1000 || yi > 1000) return INVALID_RESULT;
        double x = (double)xi, y = (double)yi;
        exy += x * y;
        ex += x;
        exx += x * x;
        ey += y;
        eyy += y * y;
    }
    exy /= (double)n;
    ex /= (double)n;
    exx /= (double)n;
    ey /= (double)n;
    eyy /= (double)n;
    double cov = exy - ex * ey;
    double varx = sqrt(exx - ex * ex);
    double vary = sqrt(eyy - ey * ey);
    if (varx * vary < DELTA) return 0.0;
    return cov / sqrt(varx * vary);
}
