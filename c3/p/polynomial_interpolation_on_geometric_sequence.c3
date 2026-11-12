module polynomial_interpolation_on_geometric_sequence;

const long MODULUS = 998244353;
const usz MAX_N = 8;
const usz MAX_INPUT = 11;

fn long normalize(long value) {
    value %= MODULUS;
    if (value < 0) value += MODULUS;
    return value;
}

fn long power_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long polynomial_interpolation_on_geometric_sequence(long* input, usz length,
    uint8* output, usz capacity) @export("polynomial_interpolation_on_geometric_sequence") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    long a = input[1], r = input[2];
    if (length != 3 + n || a < 0 || a >= MODULUS || r < 0 || r >= MODULUS) return -1;

    long[MAX_N] points = {0};
    long[MAX_N] differences = {0};
    long[MAX_N] newton = {0};
    long point = a;
    for (usz i = 0; i < n; i++) {
        points[i] = point;
        differences[i] = input[3 + i];
        if (differences[i] < 0 || differences[i] >= MODULUS) return -1;
        for (usz j = 0; j < i; j++) if (points[i] == points[j]) return -1;
        point = point * r % MODULUS;
    }

    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    if (n == 0) return 0;
    newton[0] = differences[0];
    for (usz order = 1; order < n; order++) {
        long r_order = power_mod(r, (long)order);
        usz end = n;
        while (end > order) {
            end--;
            long r_factor = power_mod(r, (long)(end - order));
            long denominator = a * r_factor % MODULUS;
            denominator = denominator * (r_order - 1) % MODULUS;
            long inverse = power_mod(normalize(denominator), MODULUS - 2);
            differences[end] = normalize((differences[end] - differences[end - 1]) * inverse);
        }
        newton[order] = differences[order];
    }

    long[MAX_N] coefficients = {0};
    long[MAX_N + 1] basis = {0};
    basis[0] = 1;
    usz degree = 0;
    for (usz order = 0; order < n; order++) {
        for (usz k = 0; k <= degree; k++)
            coefficients[k] = (coefficients[k] + newton[order] * basis[k]) % MODULUS;
        if (order + 1 == n) break;
        long[MAX_N + 1] expanded = {0};
        for (usz k = 0; k <= degree; k++) {
            expanded[k] = normalize(expanded[k] - basis[k] * points[order]);
            expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
        }
        for (usz k = 0; k <= degree + 1; k++) basis[k] = expanded[k];
        degree++;
    }
    for (usz i = 0; i < n; i++) store_le(output, 8 * i, coefficients[i]);
    return (long)bytes;
}
