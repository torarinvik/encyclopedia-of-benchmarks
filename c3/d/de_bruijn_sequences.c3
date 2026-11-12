module de_bruijn_sequences;

const usz MAX_ORDER = 16;
const usz MAX_CYCLE_LENGTH = 10000;

fn void fkm_generate(usz position, usz period, usz order, usz alphabet,
                     char* work, char* output, usz* emitted) {
    if (position > order) {
        if (order % period == 0) {
            for (usz index = 1; index <= period; index++) {
                output[(*emitted)++] = (char)(48 + work[index]);
            }
        }
        return;
    }
    work[position] = work[position - period];
    fkm_generate(position + 1, period, order, alphabet, work, output, emitted);
    for (usz symbol = (usz)work[position - period] + 1; symbol < alphabet; symbol++) {
        work[position] = (char)symbol;
        fkm_generate(position + 1, position, order, alphabet, work, output, emitted);
    }
}

fn long de_bruijn_sequences(long* input, usz length, char* output, usz output_capacity)
    @export("de_bruijn_sequences") {
    if (input == null || length != 2) return -1;
    long alphabet_value = input[0];
    long order_value = input[1];
    if (alphabet_value < 2 || alphabet_value > 10 || order_value < 1 || order_value > (long)MAX_ORDER) return -1;
    usz alphabet = (usz)alphabet_value;
    usz order = (usz)order_value;
    usz cycle_length = 1;
    for (usz step = 0; step < order; step++) {
        if (cycle_length > MAX_CYCLE_LENGTH / alphabet) return -1;
        cycle_length *= alphabet;
    }
    usz output_length = cycle_length + order - 1;
    if (output_capacity < output_length || output == null) return -2;
    char[MAX_ORDER + 1] work = zeroed;
    usz emitted = 0;
    fkm_generate(1, 1, order, alphabet, &work[0], output, &emitted);
    for (usz index = 0; index + 1 < order; index++) output[cycle_length + index] = output[index];
    return (long)output_length;
}
