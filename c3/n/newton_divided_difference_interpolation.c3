module newton_divided_difference_interpolation;

const long MODULUS = 998244353;
const usz MAX_NODES = 12;
const usz MAX_LENGTH = 27;

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn long newton_divided_difference_interpolation(long* input, usz length)
        @export("newton_divided_difference_interpolation") {
    if (input == null || length < 4 || length > MAX_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > (long)MAX_NODES) return -1;
    usz count = (usz)count_value;
    if (length != 2 + 2 * count) return -1;
    long[MAX_NODES] nodes;
    long[MAX_NODES] differences;
    for (usz i = 0; i < count; i++) {
        nodes[i] = input[1 + i];
        differences[i] = input[1 + count + i];
        if (nodes[i] < 0 || nodes[i] >= MODULUS || differences[i] < 0 || differences[i] >= MODULUS) return -1;
        for (usz j = 0; j < i; j++) if (nodes[i] == nodes[j]) return -1;
    }
    long query = input[length - 1];
    if (query < 0 || query >= MODULUS) return -1;
    for (usz order = 1; order < count; order++) {
        usz i = count;
        while (i > order) {
            i--;
            long numerator = differences[i] - differences[i - 1];
            if (numerator < 0) numerator += MODULUS;
            long denominator = nodes[i] - nodes[i - order];
            if (denominator < 0) denominator += MODULUS;
            differences[i] = (numerator * mod_pow(denominator, MODULUS - 2)) % MODULUS;
        }
    }
    long result = differences[count - 1];
    usz i = count - 1;
    while (i > 0) {
        i--;
        long factor = query - nodes[i];
        if (factor < 0) factor += MODULUS;
        result = (result * factor + differences[i]) % MODULUS;
    }
    return result;
}
