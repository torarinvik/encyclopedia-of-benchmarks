module weniger_pochhammer_partial_sum_transform;

const usz MIN_WORDS = 7;
const usz MAX_WORDS = 17;
const usz OUTPUT_BYTES = 16;

fn long weniger_gcd(long a, long b) {
    while (b != 0) { long remainder = a % b; a = b; b = remainder; }
    return a;
}

fn void weniger_store_i64(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (uchar)(bits >> (8 * byte));
}

fn long weniger_pochhammer_partial_sum_transform(long* input, usz input_length,
                                                 uchar* output, usz output_capacity)
        @export("weniger_pochhammer_partial_sum_transform") {
    if (input == null || input_length < MIN_WORDS || input_length > MAX_WORDS) return -1;
    long n0 = input[0], k0 = input[1];
    if (n0 < 0 || n0 > 8 || k0 < 3 || k0 > 4) return -1;
    usz n = (usz)n0, k = (usz)k0;
    if (input_length != n + k + 4) return -1;
    usz term_count = n + k + 2;
    for (usz i = 0; i < term_count; i++)
        if (input[i + 2] == 0 || input[i + 2] < -3 || input[i + 2] > 3) return -1;

    long product = 1;
    for (usz r = 0; r <= k; r++) product *= input[n + r + 3];
    long numerator = 0, denominator = 0;
    for (usz j = 0; j <= k; j++) {
        long choose = 1;
        for (usz r = 1; r <= j; r++) choose = choose * (long)(k - r + 1) / (long)r;
        long rising = 1;
        for (usz offset = 0; offset < k - 1; offset++) rising *= (long)(n + j + 1 + offset);
        long term = input[n + j + 3];
        long weight = choose * rising * (product / term);
        if ((j & 1) != 0) weight = -weight;
        long partial = 0;
        for (usz index = 0; index <= n + j; index++) partial += input[index + 2];
        numerator += weight * partial;
        denominator += weight;
    }
    if (denominator == 0) return -1;
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    long magnitude = numerator < 0 ? -numerator : numerator;
    long divisor = weniger_gcd(magnitude, denominator);
    numerator /= divisor;
    denominator /= divisor;
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;
    weniger_store_i64(output, 0, numerator);
    weniger_store_i64(output, 8, denominator);
    return (long)OUTPUT_BYTES;
}
