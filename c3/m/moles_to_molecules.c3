module moles_to_molecules;

const double INVALID_RESULT = -1.0e300;

fn double parse_scientific_four(double value) {
    if (value == 0.0) return 0.0;
    double normalized = value;
    int decimal_exponent = 0;
    while (normalized >= 10.0) { normalized /= 10.0; decimal_exponent++; }
    while (normalized < 1.0) { normalized *= 10.0; decimal_exponent--; }
    ulong bits = @bitcast(ulong, value);
    ulong fraction = bits & ((1ul << 52) - 1);
    int exponent_bits = (int)((bits >> 52) & 0x7ff);
    ulong significand = (1ul << 52) | fraction;
    int binary_exponent = exponent_bits - 1023 - 52;
    int decimal_shift = decimal_exponent - 4;
    ulong denominator = 1ul;
    for (int index = 0; index < decimal_shift; index++) denominator *= 5;
    int binary_shift = binary_exponent - decimal_shift;
    ulong numerator = significand;
    if (binary_shift >= 0) numerator <<= (uint)binary_shift;
    else denominator <<= (uint)(-binary_shift);
    ulong rounded = numerator / denominator;
    ulong remainder = numerator % denominator;
    if (remainder * 2 > denominator || (remainder * 2 == denominator && (rounded & 1) != 0)) rounded++;
    double decimal_scale = 1.0;
    for (int index = 0; index < decimal_shift; index++) decimal_scale *= 10.0;
    return (double)rounded * decimal_scale;
}

fn double moles_to_molecules(long* input, usz length) @export("moles_to_molecules") {
    if (input == null || length != 1) return INVALID_RESULT;
    long moles_micro = input[0];
    if (moles_micro < 0 || moles_micro > 2000000) return INVALID_RESULT;
    double moles = (double)moles_micro / 1000000.0;
    return parse_scientific_four(moles * 6.022e23);
}
