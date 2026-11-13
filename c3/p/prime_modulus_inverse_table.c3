module prime_modulus_inverse_table;

fn long prime_modulus_inverse_table(long* input, usz length, char* output, usz capacity)
        @export("prime_modulus_inverse_table") {
    const long modulus = 1000000007;
    if (input == null || length < 1 || length > 34) return -1;
    if (input[0] < 0 || input[0] > 32) return -1;
    usz count = (usz)input[0];
    if (length != count + 1) return -1;
    usz maximum = 0;
    for (usz i = 0; i < count; i++) {
        if (input[i + 1] < 1 || input[i + 1] > 256) return -1;
        if ((usz)input[i + 1] > maximum) maximum = (usz)input[i + 1];
    }
    if (count == 0) return 0;
    usz bytes = 4 * count;
    if (output == null || capacity < bytes) return -2;
    long inverse[257];
    inverse[0] = 0; inverse[1] = 1;
    for (usz i = 2; i <= maximum; i++) {
        long value = (long)i;
        inverse[i] = modulus - (modulus / value) * inverse[(usz)(modulus % value)] % modulus;
    }
    for (usz i = 0; i < count; i++) {
        long value = inverse[(usz)input[i + 1]];
        output[4*i] = (char)(value % 256);
        output[4*i+1] = (char)((value / 256) % 256);
        output[4*i+2] = (char)((value / 65536) % 256);
        output[4*i+3] = (char)(value / 16777216);
    }
    return (long)bytes;
}
