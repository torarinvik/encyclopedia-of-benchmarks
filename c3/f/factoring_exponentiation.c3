module factoring_exponentiation;

const ulong[32] FACTOR_LOG_32 = {
    0x00000000ul, 0x00000000ul, 0xd3cfd984ul, 0x9ee62e18ul,
    0xe83d9070ul, 0xb59e81e0ul, 0xa17407c0ul, 0xce601f80ul,
    0xf4807f00ul, 0xe701fe00ul, 0xbe07fc00ul, 0xfc1ff800ul,
    0xf87ff000ul, 0xf1ffe000ul, 0xe7ffc000ul, 0xdfff8000ul,
    0xffff0000ul, 0xfffe0000ul, 0xfffc0000ul, 0xfff80000ul,
    0xfff00000ul, 0xffe00000ul, 0xffc00000ul, 0xff800000ul,
    0xff000000ul, 0xfe000000ul, 0xfc000000ul, 0xf8000000ul,
    0xf0000000ul, 0xe0000000ul, 0xc0000000ul, 0x80000000ul
};

fn ulong factoring_mask(usz d) {
    return d == 32 ? 0xfffffffful : (1ul << d) - 1ul;
}

fn ulong factoring_log(ulong remainder, ulong value, usz d, ulong modulus, ulong mask) {
    for (usz bit = 2; bit < d; bit++) {
        if ((value & (1ul << bit)) != 0) {
            value = (value + (value << bit)) & mask;
            remainder = (remainder + modulus - (FACTOR_LOG_32[bit] & mask)) & mask;
        }
    }
    return remainder;
}

fn ulong factoring_exp(ulong remainder, ulong exponent, usz d, ulong modulus, ulong mask) {
    for (usz bit = 2; bit < d; bit++) {
        if ((exponent & (1ul << bit)) != 0) {
            remainder = (remainder + (remainder << bit)) & mask;
            exponent = (exponent + modulus - (FACTOR_LOG_32[bit] & mask)) & mask;
        }
    }
    return remainder;
}

fn long factoring_exponentiation(long* input, usz length) @export("factoring_exponentiation") {
    if (input == null || length != 4) return -1;
    long remainder_input = input[0];
    long base_input = input[1];
    long exponent_input = input[2];
    long d_input = input[3];
    if (d_input < 3 || d_input > 32 || remainder_input < 0 || base_input < 1 ||
        exponent_input < 0 || exponent_input > 4294967295) return -1;
    usz d = (usz)d_input;
    ulong mask = factoring_mask(d);
    ulong modulus = mask + 1ul;
    if ((ulong)remainder_input >= modulus || (ulong)base_input >= modulus ||
        (((ulong)base_input & 1ul) == 0ul)) return -1;

    ulong remainder = (ulong)remainder_input;
    ulong base = (ulong)base_input;
    ulong exponent = (ulong)exponent_input;
    if ((base & 2ul) != 0ul) {
        base = (modulus - base) & mask;
        if ((exponent & 1ul) != 0ul) remainder = (modulus - remainder) & mask;
    }
    ulong log_value = factoring_log(0ul, base, d, modulus, mask);
    ulong scaled_log = (log_value * exponent) & mask;
    return (long)factoring_exp(remainder, scaled_log, d, modulus, mask);
}
