module lz78;

const usz MAX_INPUT_LENGTH = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = 66;
const usz MAX_NODES = 65;
const usz ALPHABET_SIZE = 95;
const usz MAX_OUTPUT_BYTES = 1024;

fn void store_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long lz78_compress(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("lz78_compress") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1L;
    if (input[0] < 0 || input[0] > (long)MAX_INPUT_LENGTH) return -1L;
    usz character_count = (usz)input[0];
    if (input_length != 1 + character_count) return -1L;
    for (usz index = 0; index < character_count; index++)
        if (input[index + 1] < 32 || input[index + 1] > 126) return -1L;

    // Child id zero means absent; created nodes and phrase indices start at one.
    usz[MAX_NODES * ALPHABET_SIZE] children = zeroed;
    long[MAX_INPUT_LENGTH] token_prefix = zeroed;
    long[MAX_INPUT_LENGTH] token_character = zeroed;
    usz node_count = 1;
    usz current_node = 0;
    usz last_matched_index = 0;
    usz token_count = 0;

    for (usz index = 0; index < character_count; index++) {
        long character = input[index + 1];
        usz edge = (usz)(character - 32);
        usz child = children[current_node * ALPHABET_SIZE + edge];
        if (child != 0) {
            current_node = child;
            last_matched_index = child;
        } else {
            token_prefix[token_count] = (long)last_matched_index;
            token_character[token_count] = character;
            token_count++;
            children[current_node * ALPHABET_SIZE + edge] = node_count;
            node_count++;
            current_node = 0;
            last_matched_index = 0;
        }
    }

    if (current_node != 0) {
        token_prefix[token_count] = (long)last_matched_index;
        token_character[token_count] = 0;
        token_count++;
    }

    usz output_bytes = 16 * token_count;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1L;
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz token = 0; token < token_count; token++) {
        store_i64_le(output, 16 * token, token_prefix[token]);
        store_i64_le(output, 16 * token + 8, token_character[token]);
    }
    return (long)output_bytes;
}
