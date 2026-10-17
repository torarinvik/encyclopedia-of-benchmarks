module mass_to_moles;

const double INVALID_RESULT = -1.0e300;

fn double round_binary64_to_hundredth(double value) {
    if (value == 0.0) return 0.0;
    ulong bits = @bitcast(ulong, value);
    ulong fraction = bits & ((1ul << 52) - 1);
    int exponent_bits = (int)((bits >> 52) & 0x7ff);
    ulong significand = (1ul << 52) | fraction;
    int binary_exponent = exponent_bits - 1023 - 52;
    ulong shift = (ulong)(-binary_exponent);
    ulong scaled_significand = significand * 100;
    ulong denominator = 1ul << shift;
    ulong hundredths = scaled_significand >> shift;
    ulong remainder = scaled_significand & (denominator - 1);
    ulong halfway = denominator >> 1;
    if (remainder > halfway || (remainder == halfway && (hundredths & 1) != 0)) hundredths++;
    return (double)hundredths / 100.0;
}

fn double mass_to_moles(long* input, usz length) @export("mass_to_moles") {
    if (input == null || length != 2) return INVALID_RESULT;
    long mass = input[0], molar_mass = input[1];
    if (mass < 0 || mass > 1000 || molar_mass < 1 || molar_mass > 1000) return INVALID_RESULT;
    return round_binary64_to_hundredth((double)mass / (double)molar_mass);
}
