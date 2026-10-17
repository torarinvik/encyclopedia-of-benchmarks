module pncounter;

const usz MAX_NODES = 16;
const usz MAX_OPERATIONS = 64;
const usz MAX_INPUT_LENGTH = 5 + MAX_OPERATIONS;
const usz MAX_OUTPUT_WORDS = 2 * MAX_OPERATIONS;
const usz[6] PAIR_LEFT = {0, 0, 1, 1, 2, 2};
const usz[6] PAIR_RIGHT = {1, 2, 0, 2, 0, 1};

fn void append(long* words, usz* count, long value) {
    words[*count] = value;
    *count += 1;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long pncounter(long* input, usz length, char* output, usz output_capacity)
        @export("pncounter") {
    if (input == null || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_NODES ||
        input[4] < 0 || input[4] > (long)MAX_OPERATIONS) return -1;

    usz node_count = (usz)input[0];
    usz[3] ids;
    for (usz counter = 0; counter < 3; counter++) {
        if (input[1 + counter] < 0 || input[1 + counter] >= input[0]) return -1;
        ids[counter] = (usz)input[1 + counter];
    }
    usz operation_count = (usz)input[4];
    if (length != 5 + operation_count) return -1;

    long[3][16] positive = {0};
    long[3][16] negative = {0};
    long[MAX_OUTPUT_WORDS] words;
    usz word_count = 0;
    usz position = 5;

    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[position++];
        if (opcode < 0 || opcode > 20) return -1;
        if (opcode < 6) {
            usz counter = (usz)(opcode / 2);
            if (opcode % 2 == 0) positive[counter][ids[counter]]++;
            else negative[counter][ids[counter]]++;
            append(words, &word_count, opcode);
        } else if (opcode < 9) {
            usz counter = (usz)(opcode - 6);
            long value = 0;
            for (usz node = 0; node < node_count; node++)
                value += positive[counter][node] - negative[counter][node];
            append(words, &word_count, opcode);
            append(words, &word_count, value);
        } else if (opcode < 15) {
            usz pair = (usz)(opcode - 9);
            usz target = PAIR_LEFT[pair];
            usz source = PAIR_RIGHT[pair];
            for (usz node = 0; node < node_count; node++) {
                if (positive[target][node] < positive[source][node])
                    positive[target][node] = positive[source][node];
                if (negative[target][node] < negative[source][node])
                    negative[target][node] = negative[source][node];
            }
            append(words, &word_count, opcode);
        } else {
            usz pair = (usz)(opcode - 15);
            usz left = PAIR_LEFT[pair];
            usz right = PAIR_RIGHT[pair];
            long result = 1;
            for (usz node = 0; node < node_count; node++) {
                if (positive[left][node] > positive[right][node] &&
                    negative[left][node] > negative[right][node]) {
                    result = 0;
                    break;
                }
            }
            append(words, &word_count, opcode);
            append(words, &word_count, result);
        }
    }

    usz output_length = word_count * 8;
    if (output == null || output_capacity < output_length) return -2;
    for (usz i = 0; i < word_count; i++) put_i64_le(output, i * 8, words[i]);
    return (long)output_length;
}
