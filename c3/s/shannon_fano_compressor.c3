module shannon_fano_compressor;

const usz MAX_TEXT = 16;
const usz MAX_SYMBOLS = 16;
const usz MAX_CODE = 15;
const usz MAX_OUTPUT = 514;

fn bool make_codes(uint8* symbols, usz count, double* freq, uint8* prefix, usz depth,
                   uint8* codes, uint8* lengths) {
    if (count == 1) {
        for (usz i = 0; i < depth; i++) codes[(usz)symbols[0] * MAX_CODE + i] = prefix[i];
        lengths[(usz)symbols[0]] = (uint8)depth;
        return true;
    }
    double total = 0.0;
    for (usz i = 0; i < count; i++) total += freq[(usz)symbols[i]];
    double capacity = 0.5 * total;
    double running = 0.0;
    uint8[MAX_SYMBOLS] left = zeroed;
    uint8[MAX_SYMBOLS] right = zeroed;
    usz nl = 0, nr = 0;
    for (usz i = 0; i < count; i++) {
        uint8 symbol = symbols[i];
        if (running + freq[(usz)symbol] <= capacity) {
            left[nl++] = symbol;
            running += freq[(usz)symbol];
        } else right[nr++] = symbol;
    }
    if (nl == 0 || nr == 0 || depth >= MAX_CODE) return false;
    prefix[depth] = (uint8)'0';
    if (!make_codes(&left[0], nl, freq, prefix, depth + 1, codes, lengths)) return false;
    prefix[depth] = (uint8)'1';
    return make_codes(&right[0], nr, freq, prefix, depth + 1, codes, lengths);
}

fn long shannon_fano_compressor(long* input, usz input_length, char* output, usz capacity)
    @export("shannon_fano_compressor") {
    if (input_length > 18 || (input == null ? input_length != 0 : input_length == 0)) return -1L;
    usz text_length = 0;
    if (input != null) {
        if (input[0] < 0 || input[0] > (long)MAX_TEXT) return -1L;
        text_length = (usz)input[0];
        if (input_length != text_length + 1) return -1L;
    }
    uint8[MAX_TEXT] text = zeroed;
    uint8[MAX_SYMBOLS] symbols = zeroed;
    uint8[128] seen = zeroed;
    usz[128] counts = zeroed;
    usz symbol_count = 0;
    for (usz i = 0; i < text_length; i++) {
        long value = input[i + 1];
        if (value < 0 || value > 127) return -1L;
        text[i] = (uint8)value;
        if (seen[(usz)text[i]] == 0) { seen[(usz)text[i]] = 1; symbols[symbol_count++] = text[i]; }
        counts[(usz)text[i]] += 1;
    }
    double[128] freq = zeroed;
    if (text_length != 0) for (usz s = 0; s < 128; s++) freq[s] = (1.0 * (double)counts[s]) / (double)text_length;
    uint8[128 * MAX_CODE] codes = zeroed;
    uint8[128] lengths = zeroed;
    if (symbol_count == 1) { codes[(usz)symbols[0] * MAX_CODE] = (uint8)'1'; lengths[(usz)symbols[0]] = 1; }
    else if (symbol_count > 1) {
        uint8[MAX_CODE] prefix = zeroed;
        if (!make_codes(&symbols[0], symbol_count, &freq[0], &prefix[0], 0, &codes[0], &lengths[0])) return -1L;
    }
    char[MAX_OUTPUT] staged = zeroed;
    usz n = 0, compressed_length = 0;
    for (usz i = 0; i < text_length; i++) compressed_length += (usz)lengths[(usz)text[i]];
    staged[n++] = (char)compressed_length;
    for (usz i = 0; i < text_length; i++) for (usz j = 0; j < (usz)lengths[(usz)text[i]]; j++) staged[n++] = (char)codes[(usz)text[i] * MAX_CODE + j];
    staged[n++] = (char)symbol_count;
    for (usz s = 0; s < 128; s++) if (lengths[s] != 0) {
        staged[n++] = (char)s; staged[n++] = (char)lengths[s];
        for (usz j = 0; j < (usz)lengths[s]; j++) staged[n++] = (char)codes[s * MAX_CODE + j];
    }
    if (output == null || capacity < n) return -2L;
    for (usz i = 0; i < n; i++) output[i] = staged[i];
    return (long)n;
}
