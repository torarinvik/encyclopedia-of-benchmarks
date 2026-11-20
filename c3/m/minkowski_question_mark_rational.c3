module minkowski_question_mark_rational;

const long MAX_DENOMINATOR = 1000000;
const long MAX_CF_SUM = 60;

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255ul);
        bits >>= 8;
    }
}

fn long continued_sum(long numerator, long denominator) {
    long total = 0;
    while (numerator != 0) {
        long quotient = denominator / numerator;
        if (quotient > MAX_CF_SUM - total) return -1;
        total += quotient;
        long remainder = denominator % numerator;
        denominator = numerator;
        numerator = remainder;
    }
    return total;
}

fn long dyadic_numerator(long numerator, long denominator, long total) {
    long value = 0, prefix = 0, index = 1;
    while (numerator != 0) {
        long quotient = denominator / numerator;
        prefix += quotient;
        long shift = total - prefix;
        long term = 1L << shift;
        if ((index & 1) != 0) value += term;
        else value -= term;
        long remainder = denominator % numerator;
        denominator = numerator;
        numerator = remainder;
        index++;
    }
    return value;
}

fn long minkowski_question_mark_rational(long *input, usz length,
    char *output, usz capacity) @export("minkowski_question_mark_rational") {
    if (input == null || length < 1 || length > 3) return -1;
    if (length != 2) return -1;
    long p = input[0], q = input[1];
    if (p < 0 || q < 1 || q > MAX_DENOMINATOR || p > q) return -1;
    long total = continued_sum(p, q);
    if (total < 0) return -1;
    if (output == null || capacity < 16) return -2;
    long answer = dyadic_numerator(p, q, total);
    long exponent = total == 0 ? 0 : total - 1;
    store_i64_le(output, 0, answer);
    store_i64_le(output, 8, exponent);
    return 16;
}
