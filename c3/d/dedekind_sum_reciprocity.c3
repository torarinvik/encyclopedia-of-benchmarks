module dedekind_sum_reciprocity;

const long DEDEKIND_MAX_MODULUS = 100000;
const usz DEDEKIND_MAX_LENGTH = 3;
const long DEDEKIND_OFFSET = 29999700001;

fn long dedekind_gcd(long left, long right) {
    while (right != 0) {
        long remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

fn long dedekind_scaled(long numerator, long modulus) {
    if (modulus == 1) return 0;
    long tail = dedekind_scaled(modulus % numerator, numerator);
    long top = numerator * numerator + modulus * modulus + 1 -
               3 * numerator * modulus - modulus * tail;
    return top / numerator;
}

fn long dedekind_sum_reciprocity(long* input, usz length)
        @export("dedekind_sum_reciprocity") {
    if (input == null || length < 2 || length > DEDEKIND_MAX_LENGTH) return -1;
    long numerator = input[0], modulus = input[1];
    if (length != 2 || modulus < 1 || modulus > DEDEKIND_MAX_MODULUS ||
        numerator < 0 || numerator >= modulus ||
        dedekind_gcd(numerator, modulus) != 1) return -1;
    return DEDEKIND_OFFSET + dedekind_scaled(numerator, modulus);
}
