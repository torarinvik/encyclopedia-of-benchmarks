module charoccurrence;

const usz MAX_INPUT = 128;
const usz MAX_OUTPUT = 1024;

fn usz append_decimal(char* buffer, usz offset, usz value) {
    char[3] digits;
    usz count = 0;
    do {
        digits[count++] = (char)('0' + (char)(value % 10));
        value /= 10;
    } while (value != 0);
    while (count > 0) {
        count--;
        buffer[offset++] = digits[count];
    }
    return offset;
}

fn long charoccurrence(long* values, usz length, char* output, usz capacity) @export("charoccurrence") {
    if (length > MAX_INPUT || (length > 0 && values == null)) return -1;
    usz[128] counts = zeroed;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 127) return -1;
        counts[(usz)values[index]]++;
    }

    char[MAX_OUTPUT] encoded;
    usz used = 0;
    for (usz codepoint = 0; codepoint < 128; codepoint++) {
        if (counts[codepoint] == 0) continue;
        if (used > 0) encoded[used++] = ',';
        used = append_decimal(&encoded[0], used, codepoint);
        encoded[used++] = '=';
        used = append_decimal(&encoded[0], used, counts[codepoint]);
    }
    if (used > capacity) return -2;
    if (used > 0 && output == null) return -2;
    for (usz index = 0; index < used; index++) output[index] = encoded[index];
    return (long)used;
}
