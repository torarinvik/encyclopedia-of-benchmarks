module rabin_content_defined_chunking;

fn ushort cdc_reduce(uint value) {
    for (int bit = 31; bit >= 16; bit -= 1)
        if ((value & (1u << bit)) != 0) value ^= 0x1100bu << (bit - 16);
    return (ushort)value;
}

long rabin_content_defined_chunking(long* input, usz length, char* output, usz capacity)
        @export("rabin_content_defined_chunking") {
    if (input == null || length < 1 || length > 65 || input[0] < 0 || input[0] > 64) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i += 1) if (input[i+1] < 0 || input[i+1] > 255) return -1;
    ushort[256] outgoing = zeroed;
    for (usz i = 0; i < 256; i += 1) outgoing[i] = cdc_reduce((uint)i << 24);
    ushort fingerprint = 0;
    char[64] boundaries = zeroed;
    usz count = 0;
    for (usz i = 0; i < n; i += 1) {
        fingerprint = cdc_reduce(((uint)fingerprint << 8) | (uint)input[i+1]);
        if (i >= 4) fingerprint ^= outgoing[(usz)input[i-3]];
        if ((fingerprint & 7) == 0) { boundaries[count] = (char)(i+1); count += 1; }
    }
    if (n > 0 && (count == 0 || (usz)boundaries[count-1] != n)) { boundaries[count] = (char)n; count += 1; }
    if (output == null || capacity < count) return -2;
    for (usz i = 0; i < count; i += 1) output[i] = boundaries[i];
    return (long)count;
}
