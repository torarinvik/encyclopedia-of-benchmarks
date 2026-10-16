module gradient_descent;
const double INVALID = -1.0e300;
fn double gradient_descent(long* v, usz n) @export("gradient_descent") {
    if (v == null || n < 5 || n > 68) return INVALID;
    long d = v[0];
    long selected = v[1];
    long rate = v[2];
    long iterations = v[3];
    if (d < 1 || d > 64 || selected < 0 || selected >= d || n != 4 + (usz)d || rate < 1 || rate > 500000 || iterations < 0 || iterations > 10000) return INVALID;
    double[64] x;
    for (usz i = 0; i < (usz)d; i++) {
        if (v[4 + i] < -10 || v[4 + i] > 10) return INVALID;
        x[i] = (double)v[4 + i];
    }
    double alpha = (double)rate / 1000000.0;
    for (long k = 0; k < iterations; k++) {
        double[64] gradient;
        for (usz i = 0; i < (usz)d; i++) gradient[i] = 2.0 * x[i];
        for (usz i = 0; i < (usz)d; i++) x[i] -= alpha * gradient[i];
    }
    return x[(usz)selected];
}
