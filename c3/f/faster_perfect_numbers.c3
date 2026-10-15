module faster_perfect_numbers;

const long MAX_INPUT = 2305843009213693951L;

fn ulong get_prime_limit(long value) {
    ulong scaled = (ulong)value * 8ul + 1ul;
    ulong limit = 0;
    while (scaled >= 4ul) {
        scaled /= 4ul;
        limit++;
    }
    return limit;
}

fn bool is_prime(ulong value) {
    if (value < 2ul) return false;
    for (ulong divisor = 2ul; divisor * divisor <= value; divisor++) {
        if (value % divisor == 0ul) return false;
    }
    return true;
}

fn bool is_mersenne_prime(ulong exponent) {
    if (exponent == 2ul) return true;
    if (exponent < 2ul) return false;
    ulong modulus = (1ul << exponent) - 1ul;
    ulong residue = 4ul;
    for (ulong iteration = 0ul; iteration < exponent - 2ul; iteration++) {
        residue = (residue * residue - 2ul) % modulus;
    }
    return residue == 0ul;
}

fn long faster_perfect_numbers(long value, char* output, usz output_capacity)
    @export("faster_perfect_numbers")
{
    if (value < 0 || value > MAX_INPUT) return -1;
    long[8] perfects;
    usz count = 0;
    ulong limit = get_prime_limit(value);
    for (ulong exponent = 2ul; exponent <= limit; exponent++) {
        if (!is_prime(exponent) || !is_mersenne_prime(exponent)) continue;
        ulong mersenne = (1ul << exponent) - 1ul;
        ulong perfect = mersenne * (1ul << (exponent - 1ul));
        if (perfect <= (ulong)value) perfects[count++] = (long)perfect;
    }
    usz required = count * 8;
    if (required > 0 && output == null) return -2;
    if (output_capacity < required) return -2;
    for (usz index = 0; index < count; index++) {
        ulong bits = (ulong)perfects[index];
        for (usz byte = 0; byte < 8; byte++) {
            output[index * 8 + byte] = (char)((bits >> (ulong)(byte * 8)) & 255ul);
        }
    }
    return (long)required;
}
