module lz78_run_length_transform;

const usz MAX_TEXT_LENGTH = 32;
const usz MAX_PARSEABLE_INPUT_LENGTH = 34;
const usz MAX_TRIE_NODES = 33;
const usz MAX_TOKENS = 32;
const usz MAX_OUTPUT_BYTES = 776;
const usz ALPHABET_SIZE = 4;

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long lz78_run_length_transform(long* input, usz input_length,
        uint8* output, usz output_capacity) @export("lz78_run_length_transform") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < 0 || input[0] > (long)MAX_TEXT_LENGTH) return -1L;
    usz n = (usz)input[0];
    if (input_length != n + 1) return -1L;
    for (usz i = 0; i < n; i++)
        if (input[i + 1] < 1 || input[i + 1] > 3) return -1L;

    long[MAX_TEXT_LENGTH] transformed = zeroed;
    usz transformed_length = 0;
    usz position = 0;
    while (position < n) {
        long symbol = input[position + 1];
        usz end = position + 1;
        while (end < n && input[end + 1] == symbol) end++;
        usz run_length = end - position;
        usz highest_bit = 0;
        usz value = run_length;
        while (value > 1) { value >>= 1; highest_bit++; }
        usz bit = highest_bit + 1;
        while (bit > 0) {
            bit--;
            transformed[transformed_length] = if ((run_length >> bit) & 1) != 0 then symbol else 0;
            transformed_length++;
        }
        position = end;
    }

    usz[MAX_TRIE_NODES * ALPHABET_SIZE] children = zeroed;
    long[MAX_TOKENS * 3] tokens = zeroed;
    usz token_count = 0;
    usz text_position = 0;
    usz next_phrase_id = 1;
    while (text_position < transformed_length) {
        usz node = 0;
        usz end = text_position;
        while (end < transformed_length) {
            usz child = children[node * ALPHABET_SIZE + (usz)transformed[end]];
            if (child == 0) break;
            node = child;
            end++;
        }
        if (end == transformed_length) {
            if (node != 0) {
                tokens[token_count * 3] = (long)node;
                tokens[token_count * 3 + 1] = 0;
                tokens[token_count * 3 + 2] = 1;
                token_count++;
            }
            break;
        }
        usz symbol = (usz)transformed[end];
        tokens[token_count * 3] = (long)node;
        tokens[token_count * 3 + 1] = (long)symbol;
        tokens[token_count * 3 + 2] = 0;
        token_count++;
        children[node * ALPHABET_SIZE + symbol] = next_phrase_id;
        next_phrase_id++;
        text_position = end + 1;
    }

    usz output_bytes = 8 + 24 * token_count;
    uint8[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, (long)token_count);
    for (usz token = 0; token < token_count; token++)
        for (usz field = 0; field < 3; field++)
            store_i64_le(&staged[0], 8 + 24 * token + 8 * field, tokens[token * 3 + field]);
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz byte = 0; byte < output_bytes; byte++) output[byte] = staged[byte];
    return (long)output_bytes;
}
