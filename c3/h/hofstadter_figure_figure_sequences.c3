module hofstadter_figure_figure_sequences;

const usz MAX_TERMS = 64;
const usz MAX_WORDS = 129;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long hofstadter_figure_figure_sequences(long* input, usz length, char* output,
    usz capacity) @export("hofstadter_figure_figure_sequences") {
    if (input == null || length == 0 || length > 2) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_TERMS || length != 1) return -1;
    usz n = (usz)input[0];
    long[MAX_TERMS] figure = zeroed;
    long[MAX_TERMS] space = zeroed;
    figure[0] = 1;
    space[0] = 2;
    long candidate = 3;
    for (usz i = 1; i < n; i++) {
        figure[i] = figure[i-1] + space[i-1];
        bool used = true;
        while (used) {
            used = false;
            for (usz j = 0; j <= i; j++) if (figure[j] == candidate) used = true;
            if (used) candidate++;
        }
        space[i] = candidate;
        candidate++;
    }
    usz word_count = 1 + 2*n;
    usz output_bytes = word_count*8;
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_WORDS] words = zeroed;
    words[0] = (long)n;
    for (usz i = 0; i < n; i++) { words[1+i] = figure[i]; words[1+n+i] = space[i]; }
    for (usz i = 0; i < word_count; i++) write_i64_le(output, i*8, words[i]);
    return (long)output_bytes;
}
