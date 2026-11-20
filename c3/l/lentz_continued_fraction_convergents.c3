module lentz_continued_fraction_convergents;

const usz MAX_TERMS = 8;
const usz MAX_INPUT_LENGTH = 19;
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

fn long lentz_continued_fraction_convergents(long* input, usz length,
        char* output, usz capacity) @export("lentz_continued_fraction_convergents") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = input[0];
    if (count_value < 1 || count_value > (long)MAX_TERMS) return -1;
    usz count = (usz)count_value;
    if (length != 2 + 2 * count) return -1;
    for (usz i = 1; i < length; i++)
        if (input[i] < 0 || input[i] >= MODULUS) return -1;
    long value = input[1];
    if (value == 0) return -1;
    long c_ratio = value;
    long d_ratio = 0;
    long[MAX_TERMS + 2] trace;
    for (usz i = 0; i < MAX_TERMS + 2; i++) trace[i] = 0;
    trace[0] = value;
    for (usz index = 0; index < count; index++) {
        long numerator = input[2 + 2 * index];
        long denominator = input[3 + 2 * index];
        long d_denominator = normalize(denominator + numerator * d_ratio);
        if (d_denominator == 0 || c_ratio == 0) return -1;
        long c_value = normalize(denominator + numerator * power(c_ratio, MODULUS - 2));
        if (c_value == 0) return -1;
        d_ratio = power(d_denominator, MODULUS - 2);
        value = value * c_value % MODULUS * d_ratio % MODULUS;
        c_ratio = c_value;
        trace[index + 1] = value;
    }
    usz output_bytes = 8 * (count + 2);
    if (output == null || capacity < output_bytes) return -2;
    store_i64_le(output, 0, (long)(count + 1));
    for (usz i = 0; i <= count; i++) store_i64_le(output, 8 * (i + 1), trace[i]);
    return (long)output_bytes;
}
