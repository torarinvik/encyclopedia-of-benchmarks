module z_function;

fn long z_function(long* input, usz length, char* output, usz capacity) @export("z_function") {
    if (length > 256 || (length > 0 && input == null)) return -1;
    for (usz i = 0; i < length; i++) if (input[i] < 0 || input[i] > 127) return -1;
    usz required = length * 8;
    if (capacity < required || (required > 0 && output == null)) return -2;

    long[256] z;
    for (usz i = 0; i < length; i++) z[i] = 0;
    usz left = 0, right = 0;
    for (usz i = 1; i < length; i++) {
        if (i <= right) {
            usz prior = (usz)z[i - left];
            usz window = right - i + 1;
            z[i] = (long)(window < prior ? window : prior);
        }
        while (i + (usz)z[i] < length && input[(usz)z[i]] == input[i + (usz)z[i]]) z[i]++;
        if (i + (usz)z[i] > right + 1) {
            left = i;
            right = i + (usz)z[i] - 1;
        }
    }
    for (usz i = 0; i < length; i++) {
        ulong bits = (ulong)z[i];
        for (usz byte = 0; byte < 8; byte++) {
            output[8 * i + byte] = (char)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)required;
}
