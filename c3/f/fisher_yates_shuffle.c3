module fisher_yates_shuffle;

fn long fisher_yates_shuffle(long* input, usz length, char* output, usz output_capacity)
    @export("fisher_yates_shuffle") {
    const usz MAX_VALUES = 1024;
    const ulong MODULUS = 2147483647;
    if (input == null || length < 1 || length > MAX_VALUES + 1) return -1;
    long seed = input[0];
    if (seed < 1 || seed >= 2147483647) return -1;
    usz count = length - 1;
    int[MAX_VALUES] values;
    for (usz i = 0; i < count; i++) {
        long value = input[i + 1];
        if (value < -2147483648 || value > 2147483647) return -1;
        values[i] = (int)value;
    }
    usz byte_count = count * 4;
    if (output_capacity < byte_count || (byte_count != 0 && output == null)) return -2;
    ulong state = (ulong)seed;
    usz remaining = count;
    while (remaining >= 2) {
        state = (state * 48271) % MODULUS;
        usz other = (usz)(state % (ulong)remaining);
        int temporary = values[remaining - 1];
        values[remaining - 1] = values[other];
        values[other] = temporary;
        remaining--;
    }
    for (usz i = 0; i < count; i++) {
        uint bits = (uint)values[i];
        for (usz byte = 0; byte < 4; byte++) {
            output[i * 4 + byte] = (char)((bits >> (byte * 8)) & 255);
        }
    }
    return (long)count;
}
