module z_algorithm_search;

const usz MAX_SEQUENCE_LENGTH = 2047;
const usz MAX_CONCAT_LENGTH = 4095;

fn uint fold_ascii(long value) {
    uint byte = (uint)value;
    if (byte >= 'A' && byte <= 'Z') return byte + ('a' - 'A');
    return byte;
}

fn long z_algorithm_search(long* values, usz length, char* output, usz output_capacity)
        @export("z_algorithm_search") {
    if (values == null || length < 2) return -1;
    if (values[0] < 0 || values[1] < 0) return -1;
    if ((usz)values[0] > MAX_SEQUENCE_LENGTH || (usz)values[1] > MAX_SEQUENCE_LENGTH) return -1;
    usz text_length = (usz)values[0]; usz pattern_length = (usz)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (usz i = 2; i < length; i++) if (values[i] < 0 || values[i] > 127) return -1;
    if (pattern_length == 0) {
        usz count = text_length + 1;
        if (output_capacity < 4 * count || output == null) return -2;
        for (usz i = 0; i < count; i++) { uint p = (uint)(i + 1); for (usz b = 0; b < 4; b++) output[4 * i + b] = (char)(p >> (8 * b)); }
        return (long)count;
    }
    uint[MAX_CONCAT_LENGTH] sequence;
    usz[MAX_CONCAT_LENGTH] z;
    usz total = pattern_length + 1 + text_length;
    for (usz i = 0; i < pattern_length; i++) sequence[i] = fold_ascii(values[2 + text_length + i]);
    sequence[pattern_length] = 256;
    for (usz i = 0; i < text_length; i++) sequence[pattern_length + 1 + i] = fold_ascii(values[2 + i]);
    for (usz i = 0; i < total; i++) z[i] = 0;
    usz left = 0; usz right = 0;
    for (usz i = 1; i < total; i++) {
        if (i < right) { usz remaining = right - i; z[i] = z[i - left] < remaining ? z[i - left] : remaining; }
        while (i + z[i] < total && sequence[z[i]] == sequence[i + z[i]]) z[i]++;
        if (i + z[i] > right) { left = i; right = i + z[i]; }
    }
    usz count = 0;
    for (usz i = pattern_length + 1; i < total; i++) if (z[i] >= pattern_length) count++;
    if (output_capacity < 4 * count || (count > 0 && output == null)) return -2;
    usz write = 0;
    for (usz i = pattern_length + 1; i < total; i++) if (z[i] >= pattern_length) {
        uint p = (uint)(i - pattern_length);
        for (usz b = 0; b < 4; b++) output[4 * write + b] = (char)(p >> (8 * b));
        write++;
    }
    return (long)count;
}
