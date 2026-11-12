module sum_of_exponential_times_polynomial_limit;

const long MODULUS = 998244353;
const long MAX_DEGREE = 256;

fn long seppl_mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 == 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent /= 2;
    }
    return result;
}

// Infinite geometric-weighted power sum via an Eulerian polynomial row.
fn long sum_of_exponential_times_polynomial_limit(long* input, usz length) @export("sum_of_exponential_times_polynomial_limit") {
    if (input == null || length != 2) return -1;
    long r = input[0];
    long degree_value = input[1];
    if (r < 0 || r >= MODULUS || r == 1 || degree_value < 0 || degree_value > MAX_DEGREE) return -1;
    usz degree = (usz)degree_value;
    long denominator = (1 - r + MODULUS) % MODULUS;
    long inverse = seppl_mod_pow(denominator, MODULUS - 2);
    if (degree == 0) return inverse;

    long[MAX_DEGREE + 1] row = zeroed;
    long[MAX_DEGREE + 1] next = zeroed;
    row[0] = 1;
    for (usz n = 1; n <= degree; n++) {
        for (usz k = 0; k <= n; k++) {
            long value = 0;
            if (k > 0) value += (long)(n - k) * row[k - 1];
            if (k < n) value += (long)(k + 1) * row[k];
            next[k] = value % MODULUS;
        }
        for (usz k = 0; k <= n; k++) {
            row[k] = next[k];
            next[k] = 0;
        }
    }

    long eulerian_value = 0;
    usz k = degree;
    while (k > 0) {
        k -= 1;
        eulerian_value = (eulerian_value * r + row[k]) % MODULUS;
    }
    long denominator_power = seppl_mod_pow(inverse, (long)degree + 1);
    return r * eulerian_value % MODULUS * denominator_power % MODULUS;
}
