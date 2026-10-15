module minkowski_distance;

extern fn double pow(double base, double exponent);

const long MAX_N = 8;
const long MAX_P = 6;
const double INVALID_RESULT = -1.0e300;

fn double minkowski_distance(long* packed, usz length) @export("minkowski_distance") {
    if (length < 2 || length > 18) return INVALID_RESULT;
    long n = packed[0];
    long p = packed[1];
    if (n < 0 || n > MAX_N || p < 3 || p > MAX_P || length != (usz)(2 + 2 * n)) return INVALID_RESULT;
    for (long i = 0; i < n; i++) {
        if (packed[2 + (usz)i] < -100 || packed[2 + (usz)i] > 100 || packed[2 + (usz)n + (usz)i] < -100 || packed[2 + (usz)n + (usz)i] > 100) return INVALID_RESULT;
    }
    long sum = 0;
    for (long i = 0; i < n; i++) {
        long difference = packed[2 + (usz)i] - packed[2 + (usz)n + (usz)i];
        if (difference < 0) difference = -difference;
        long term = 1;
        for (long exponent = 0; exponent < p; exponent++) term *= difference;
        sum += term;
    }
    return pow((double)sum, 1.0 / (double)p);
}
