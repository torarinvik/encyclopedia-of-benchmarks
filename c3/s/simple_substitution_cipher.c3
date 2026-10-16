module simple_substitution_cipher;

fn long simple_substitution_cipher(long* input, usz length, char* output, usz output_capacity)
        @export("simple_substitution_cipher") {
    if (input == null || length < 28 || length > 284) return -1;
    long mode = input[0], n64 = input[27];
    if ((mode != 0 && mode != 1) || n64 < 0 || n64 > 256 || length != 28 + (usz)n64) return -1;
    bool[26] seen;
    for (usz i = 0; i < 26; i++) {
        long value = input[1 + i];
        if (value < 65 || value > 90 || seen[(usz)(value - 65)]) return -1;
        seen[(usz)(value - 65)] = true;
    }
    usz n = (usz)n64;
    for (usz i = 0; i < n; i++) if (input[28 + i] < 0 || input[28 + i] > 127) return -1;
    if (output == null || output_capacity < n) return -2;
    for (usz i = 0; i < n; i++) {
        long ch = input[28 + i];
        bool lower = ch >= 97 && ch <= 122, upper = ch >= 65 && ch <= 90;
        if (!lower && !upper) { output[i] = (char)ch; continue; }
        long index = ch - (lower ? 97 : 65), mapped = index;
        if (mode == 0) mapped = input[1 + (usz)index] - 65;
        else {
            mapped = 0;
            while (mapped < 26 && input[1 + (usz)mapped] != 65 + index) mapped++;
        }
        output[i] = (char)((lower ? 97 : 65) + mapped);
    }
    return (long)n;
}
