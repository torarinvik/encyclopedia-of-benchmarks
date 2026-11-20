module three_prime_carmichael_enumerator;

const long MAX_LIMIT = 61;
const long MAX_TRIPLES = 69;
const usz MAX_PARSEABLE_LENGTH = 2;

fn bool is_prime(long value) {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    long divisor = 3;
    while (divisor <= value / divisor) {
        if (value % divisor == 0) return false;
        divisor += 2;
    }
    return true;
}

fn long mod_nonnegative(long value, long modulus) {
    long result = value % modulus;
    return result < 0 ? result + modulus : result;
}

fn void put_u32_le(char* output, usz offset, uint value) {
    for (usz byte = 0; byte < 4; ++byte)
        output[offset + byte] = (char)((value >> (8 * byte)) & 255);
}

fn long three_prime_carmichael_enumerator(long* input, usz length,
                                           char* output, usz capacity)
    @export("three_prime_carmichael_enumerator") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH || length != 1) return -1;
    long limit = input[0];
    if (limit < 2 || limit > MAX_LIMIT) return -1;

    uint[MAX_TRIPLES * 3] triples;
    usz count = 0;
    for (long p1 = 2; p1 <= limit; ++p1) {
        if (!is_prime(p1)) continue;
        for (long h3 = 2; h3 < p1; ++h3) {
            long g = h3 + p1;
            for (long d = 1; d < g; ++d) {
                if ((g * (p1 - 1)) % d != 0) continue;
                if (mod_nonnegative(-p1 * p1, h3) != d % h3) continue;
                long p2 = 1 + (p1 - 1) * g / d;
                if (p2 <= p1 || !is_prime(p2)) continue;
                long p3 = 1 + (p1 * p2) / h3;
                if (p3 <= p2 || !is_prime(p3)) continue;
                if ((p2 * p3) % (p1 - 1) != 1) continue;
                if (count >= MAX_TRIPLES) return -1;
                triples[3 * count] = (uint)p1;
                triples[3 * count + 1] = (uint)p2;
                triples[3 * count + 2] = (uint)p3;
                count++;
            }
        }
    }

    usz required = 4 + 12 * count;
    if (output == null || capacity < required) return -2;
    put_u32_le(output, 0, (uint)count);
    for (usz i = 0; i < count; ++i) {
        for (usz field = 0; field < 3; ++field)
            put_u32_le(output, 4 + 12 * i + 4 * field, triples[3 * i + field]);
    }
    return (long)required;
}
