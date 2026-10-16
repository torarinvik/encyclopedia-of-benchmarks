module egyptian_fraction;

// Return source-ordered unit-fraction denominators as little-endian i32s.
fn long egyptian_fraction(long* input, usz length, char* output, usz output_capacity)
        @export("egyptian_fraction") {
    if (input == null || length != 2) return -1;
    long numerator = input[0], denominator = input[1];
    if (numerator < 0 || denominator < 1 || denominator > 10 || numerator > denominator) return -1;

    uint[10] terms;
    usz count = 0;
    while (numerator != 0) {
        long unit_denominator = denominator / numerator;
        if (denominator % numerator != 0) unit_denominator++;
        terms[count++] = (uint)unit_denominator;
        numerator = numerator * unit_denominator - denominator;
        denominator = denominator * unit_denominator;
    }
    usz required = count * 4;
    if (output_capacity < required || (required > 0 && output == null)) return -2;
    for (usz index = 0; index < count; index++) {
        uint value = terms[index];
        for (usz byte = 0; byte < 4; byte++) output[index * 4 + byte] = (char)((value >> (8 * byte)) & 255);
    }
    return (long)required;
}
