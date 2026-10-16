module trifid_cipher;

const MAX_TEXT = 256;

fn long trifid_cipher(long* input, usz length, char* output, usz output_capacity)
    @export("trifid_cipher") {
    if (input == null || length < 31) return -1;
    long mode = input[0];
    long period_value = input[1];
    long n_value = input[2];
    if ((mode != 0 && mode != 1) || period_value < 1 || period_value > 256 ||
        n_value < 0 || n_value > MAX_TEXT || input[3] != 27 || length != (usz)(31 + n_value)) return -1;
    char[27] alphabet;
    char[MAX_TEXT] text;
    char[MAX_TEXT] transformed;
    usz alen = 0;
    usz tlen = 0;
    for (usz i = 0; i < 27; i++) {
        long raw = input[4 + (usz)n_value + i];
        if (raw < 0 || raw > 127) return -1;
        char c = (char)raw;
        if (c >= 'a' && c <= 'z') c -= 32;
        if (c == ' ') continue;
        for (usz j = 0; j < alen; j++) if (alphabet[j] == c) return -1;
        alphabet[alen++] = c;
    }
    if (alen != 27) return -1;
    for (usz i = 0; i < (usz)n_value; i++) {
        long raw = input[4 + i];
        if (raw < 0 || raw > 127) return -1;
        char c = (char)raw;
        if (c >= 'a' && c <= 'z') c -= 32;
        if (c == ' ') continue;
        bool found = false;
        for (usz j = 0; j < 27; j++) if (alphabet[j] == c) found = true;
        if (!found) return -1;
        text[tlen++] = c;
    }
    usz start = 0;
    usz period = (usz)period_value;
    while (start < tlen) {
        usz k = period < tlen - start ? period : tlen - start;
        char[768] digits;
        if (mode == 0) {
            usz m = 0;
            for (usz axis = 0; axis < 3; axis++) for (usz i = 0; i < k; i++) {
                usz index = 0;
                while (alphabet[index] != text[start + i]) index++;
                usz divisor = axis == 0 ? 9 : axis == 1 ? 3 : 1;
                digits[m++] = (char)((index / divisor) % 3);
            }
            for (usz i = 0; i < m; i += 3) {
                usz index = (usz)digits[i] * 9 + (usz)digits[i + 1] * 3 + (usz)digits[i + 2];
                transformed[start + i / 3] = alphabet[index];
            }
        } else {
            for (usz i = 0; i < k; i++) {
                usz index = 0;
                while (alphabet[index] != text[start + i]) index++;
                digits[3 * i] = (char)((index / 9) % 3);
                digits[3 * i + 1] = (char)((index / 3) % 3);
                digits[3 * i + 2] = (char)(index % 3);
            }
            for (usz i = 0; i < k; i++) {
                usz index = (usz)digits[i] * 9 + (usz)digits[k + i] * 3 + (usz)digits[2 * k + i];
                transformed[start + i] = alphabet[index];
            }
        }
        start += k;
    }
    if (output_capacity < tlen) return -2;
    if (tlen > 0 && output == null) return -1;
    for (usz i = 0; i < tlen; i++) output[i] = transformed[i];
    return (long)tlen;
}
