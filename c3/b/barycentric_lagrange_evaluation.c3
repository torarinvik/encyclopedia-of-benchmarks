module barycentric_lagrange_evaluation;

const long MODULUS = 998244353;
const usz MAX_INPUT_LENGTH = 19;
const usz MAX_NODES = 8;

fn long mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn long barycentric_lagrange_evaluation(long *input, usz length)
        @export("barycentric_lagrange_evaluation") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > (long)MAX_NODES) return -1;
    usz count = (usz)count_value;
    if (length != 2 * count + 2) return -1;
    for (usz index = 1; index < length; index++)
        if (input[index] < 0 || input[index] >= MODULUS) return -1;
    for (usz left = 0; left < count; left++)
        for (usz right = 0; right < left; right++)
            if (input[1 + left] == input[1 + right]) return -1;

    long[MAX_NODES] weights = {};
    for (usz index = 0; index < count; index++) {
        long product = 1;
        long node = input[1 + index];
        for (usz other = 0; other < count; other++) {
            if (other == index) continue;
            long difference = (node - input[1 + other] + MODULUS) % MODULUS;
            product = product * difference % MODULUS;
        }
        weights[index] = mod_pow(product, MODULUS - 2);
    }

    usz ordinate_start = 1 + count;
    long query = input[2 * count + 1];
    for (usz index = 0; index < count; index++)
        if (query == input[1 + index]) return input[ordinate_start + index];
    long numerator = 0;
    long denominator = 0;
    for (usz index = 0; index < count; index++) {
        long difference = (query - input[1 + index] + MODULUS) % MODULUS;
        long term = weights[index] * mod_pow(difference, MODULUS - 2) % MODULUS;
        numerator = (numerator + term * input[ordinate_start + index]) % MODULUS;
        denominator = (denominator + term) % MODULUS;
    }
    if (denominator == 0) return -1;
    return numerator * mod_pow(denominator, MODULUS - 2) % MODULUS;
}
