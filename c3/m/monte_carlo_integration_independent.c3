module monte_carlo_integration_independent;

const long MAX_N = 16;
const long MIN_BOUND = -10000000;
const long MAX_BOUND = 10000000;
const long MAX_UNIFORM = 999999;
const double INVALID_RESULT = -1.0e300;

fn double monte_carlo_integration_independent(long* packed, usz length) @export("monte_carlo_integration_independent") {
    if (packed == null || length < 3 || length > 20) return INVALID_RESULT;
    long n = packed[2];
    if (n < 1 || n > MAX_N || length != (usz)(3 + n)) return INVALID_RESULT;
    long a_raw = packed[0];
    long b_raw = packed[1];
    if (a_raw < MIN_BOUND || a_raw > MAX_BOUND || b_raw < MIN_BOUND || b_raw > MAX_BOUND || a_raw >= b_raw) return INVALID_RESULT;
    for (usz i = 3; i < length; i++) {
        if (packed[i] < 0 || packed[i] > MAX_UNIFORM) return INVALID_RESULT;
    }

    double a = (double)a_raw / 1000000.0;
    double b = (double)b_raw / 1000000.0;
    double interval = b - a;
    double delta = interval / (double)n;
    double total = 0.0;
    for (long i = 0; i < n; i++) {
        double u = (double)packed[3 + (usz)i] / 1000000.0;
        double x = a + interval * u;
        total += x * x;
    }
    return delta * total;
}
