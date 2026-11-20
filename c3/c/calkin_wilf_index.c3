// Uncompiled indexed Calkin–Wilf fraction draft.
module calkin_wilf_index;
fn long calkin_wilf_index(long* input, usz length, char* output, usz capacity) @export("calkin_wilf_index") {
    if (input == null || length != 1) return -1;
    long raw = input[0];
    if (raw < 1 || raw >= ((long)1 << 62)) return -1;
    if (output == null || capacity < 16) return -2;
    ulong index = (ulong)raw, high = 1, numerator = 1, denominator = 1;
    while (high <= index / 2) high *= 2;
    high /= 2;
    while (high != 0) {
        if ((index & high) != 0) numerator += denominator; else denominator += numerator;
        high /= 2;
    }
    for (usz i = 0; i < 8; i++) {
        output[i] = (char)((numerator >> (8*i)) & 255);
        output[i+8] = (char)((denominator >> (8*i)) & 255);
    }
    return 16;
}
