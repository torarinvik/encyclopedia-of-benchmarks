module balanced_parenthesis_successor;

const usz MAX_PAIRS = 10;
const usz MAX_INPUT_LENGTH = 21;
const usz MAX_OUTPUT_BYTES = 20;

fn long balanced_parenthesis_successor(long* input, usz length, char* output,
        usz capacity) @export("balanced_parenthesis_successor") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long pairs_value = input[0];
    if (pairs_value < 1 || pairs_value > (long)MAX_PAIRS) return -1;
    usz pairs = (usz)pairs_value, sequence_length = 2 * pairs;
    if (length != 1 + sequence_length) return -1;
    u8[MAX_OUTPUT_BYTES] symbols = zeroed;
    long balance = 0;
    for (usz i = 0; i < sequence_length; i++) {
        long symbol = input[1 + i];
        if (symbol != 0 && symbol != 1) return -1;
        symbols[i] = (u8)symbol;
        balance += if (symbol == 0) 1 else -1;
        if (balance < 0) return -1;
    }
    if (balance != 0) return -1;
    if (output == null || capacity < sequence_length) return -2;

    char[MAX_OUTPUT_BYTES] staged = zeroed;
    long reverse_depth = 0;
    usz cursor = sequence_length;
    while (cursor > 0) {
        cursor--;
        usz i = cursor;
        if (symbols[i] == 0) reverse_depth--;
        else reverse_depth++;
        if (symbols[i] == 0 && reverse_depth > 0) {
            reverse_depth--;
            usz suffix_length = sequence_length - i - 1;
            usz opening_count = (usz)(((long)suffix_length - reverse_depth) / 2);
            usz closing_count = suffix_length - opening_count;
            for (usz j = 0; j < i; j++) staged[j] = if (symbols[j] == 0) '(' else ')';
            staged[i] = ')';
            usz position = i + 1;
            for (usz j = 0; j < opening_count; j++) { staged[position] = '('; position++; }
            for (usz j = 0; j < closing_count; j++) { staged[position] = ')'; position++; }
            for (usz j = 0; j < sequence_length; j++) output[j] = staged[j];
            return (long)sequence_length;
        }
    }
    return -3;
}
