module monte_carlo_integration;

const long MAX_N = 16;
const long MIN_BOUND = -10000000;
const long MAX_BOUND = 10000000;
const long MAX_UNIFORM = 999999;
const double INVALID_RESULT = -1.0e300;

fn double monte_carlo_integration(long* packed, usz length) @export("monte_carlo_integration") {
    if (packed == null || length < 3 || length > 12) return INVALID_RESULT;
    long n = packed[2];
    if (n < 1 || n > MAX_N || length != (usz)(3 + (n + 1) / 2)) return INVALID_RESULT;
    long a_raw = packed[0];
    long b_raw = packed[1];
    if (a_raw < MIN_BOUND || a_raw > MAX_BOUND || b_raw < MIN_BOUND || b_raw > MAX_BOUND || a_raw >= b_raw) return INVALID_RESULT;
    for (usz i = 3; i < length; i++) {
        if (packed[i] < 0 || packed[i] > MAX_UNIFORM) return INVALID_RESULT;
    }

    double a = (double)a_raw / 1000000.0;
    double b = (double)b_raw / 1000000.0;
    double interval = b - a;
    double total = 0.0;
    for (long i = 0; i < n / 2; i++) {
        double u = (double)packed[3 + (usz)i] / 1000000.0;
        double x1 = a + u * interval;
        double x2 = a + (1.0 - u) * interval;
        total += x1 * x1;
        total += x2 * x2;
    }
    if ((n & 1) == 1) {
        double u = (double)packed[3 + (usz)(n / 2)] / 1000000.0;
        double x = a + u * interval;
        total += x * x;
    }
    return interval * total / (double)n;
}
