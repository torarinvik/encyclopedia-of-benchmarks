module shannon_fano_elias_symbol_codes;

fn long shannon_fano_elias_symbol_codes(long* input, usz length, char* output, usz capacity) @export("shannon_fano_elias_symbol_codes") {
    if (input == null || length < 2 || length > 10) return -1;
    long raw_n = input[0];
    if (raw_n < 1 || raw_n > 8 || length != (usz)(raw_n + 1)) return -1;
    usz n = (usz)raw_n;
    long total = 0;
    for (usz i = 0; i < n; i++) {
        long weight = input[1 + i];
        if (weight < 1 || weight > 15) return -1;
        total += weight;
    }
    if (total > 120) return -1;

    char[17] staged = {};
    staged[0] = (char)n;
    long prefix = 0;
    for (usz i = 0; i < n; i++) {
        long weight = input[1 + i];
        usz bits = 1;
        while (((long)1 << (bits - 1)) * weight < total) bits++;
        long numerator = (2 * prefix + weight) * ((long)1 << (bits - 1));
        ulong code = (ulong)(numerator / total);
        staged[1 + 2 * i] = (char)bits;
        staged[2 + 2 * i] = (char)(code << (8 - bits));
        prefix += weight;
    }
    usz needed = 1 + 2 * n;
    if (output == null || capacity < needed) return -2;
    for (usz i = 0; i < needed; i++) output[i] = staged[i];
    return (long)needed;
}
