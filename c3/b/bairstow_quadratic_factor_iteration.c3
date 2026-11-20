module bairstow_quadratic_factor_iteration;

const usz MAX_DEGREE = 8;
const usz MAX_ITERATIONS = 4;
const usz MAX_INPUT_LENGTH = 14;
const usz MAX_OUTPUT_BYTES = 88;
const long MODULUS = 998244353;

fn long normalize(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long power(long base, long exponent) {
    long result = 1;
    base = normalize(base);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long bairstow_quadratic_factor_iteration(long* input, usz length,
        char* output, usz capacity) @export("bairstow_quadratic_factor_iteration") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long degree_value = input[0];
    if (degree_value < 3 || degree_value > (long)MAX_DEGREE) return -1;
    usz degree = (usz)degree_value;
    if (length != degree + 5) return -1;

    long[MAX_DEGREE + 1] coefficients;
    for (usz i = 0; i <= degree; i++) {
        coefficients[i] = input[1 + i];
        if (coefficients[i] < 0 || coefficients[i] >= MODULUS) return -1;
    }
    long s_value = input[degree + 2];
    long t_value = input[degree + 3];
    long iterations_value = input[degree + 4];
    if (coefficients[degree] == 0 || s_value < 0 || s_value >= MODULUS
            || t_value < 0 || t_value >= MODULUS
            || iterations_value < 1 || iterations_value > (long)MAX_ITERATIONS) return -1;
    usz iterations = (usz)iterations_value;

    long[MAX_ITERATIONS + 1] s_trace;
    long[MAX_ITERATIONS + 1] t_trace;
    for (usz i = 0; i <= MAX_ITERATIONS; i++) { s_trace[i] = 0; t_trace[i] = 0; }
    s_trace[0] = s_value;
    t_trace[0] = t_value;
    for (usz step = 0; step < iterations; step++) {
        long[MAX_DEGREE + 2] q;
        long[MAX_DEGREE + 2] r;
        for (usz i = 0; i < MAX_DEGREE + 2; i++) { q[i] = 0; r[i] = 0; }
        q[degree] = coefficients[degree];
        r[degree] = coefficients[degree];
        for (usz cursor = degree; cursor > 0; cursor--) {
            usz j = cursor - 1;
            q[j] = normalize(coefficients[j] + s_value * q[j + 1] + t_value * q[j + 2]);
            r[j] = normalize(q[j] + s_value * r[j + 1] + t_value * r[j + 2]);
        }
        long r2 = r[2], r3 = r[3], q0 = q[0], q1 = q[1];
        long ell = normalize(s_value * r2 + t_value * r3);
        long denominator = normalize(r2 * r2 - ell * r3);
        if (denominator == 0) return -1;
        long inverse = power(denominator, MODULUS - 2);
        long delta_s = normalize(r3 * q0 - r2 * q1) * inverse % MODULUS;
        long delta_t = normalize(ell * q1 - r2 * q0) * inverse % MODULUS;
        s_value = normalize(s_value + delta_s);
        t_value = normalize(t_value + delta_t);
        s_trace[step + 1] = s_value;
        t_trace[step + 1] = t_value;
    }

    usz output_bytes = 8 * (2 * iterations + 3);
    if (output == null || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (long)(iterations + 1));
    for (usz i = 0; i <= iterations; i++) {
        store_i64_le(output, 8 * (1 + 2 * i), s_trace[i]);
        store_i64_le(output, 8 * (2 + 2 * i), t_trace[i]);
    }
    return (long)output_bytes;
}
