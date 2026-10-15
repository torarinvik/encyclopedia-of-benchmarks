module sum_of_arithmetic_series;

const double INVALID_RESULT = -1.0e300;

fn double sum_of_arithmetic_series(long* packed, usz length) @export("sum_of_arithmetic_series") {
    if (length != 3) return INVALID_RESULT;
    long a = packed[0];
    long d = packed[1];
    long n = packed[2];
    if (a < -1000 || a > 1000 || d < -1000 || d > 1000 || n < 1 || n > 1000) return INVALID_RESULT;
    long result = n * (2 * a + (n - 1) * d) / 2;
    return (double)result;
}
