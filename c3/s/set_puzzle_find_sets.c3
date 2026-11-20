module set_puzzle_find_sets;

const usz MAX_CARDS = 12;
const usz MAX_INPUT_WORDS = 14;
const usz DECK_SIZE = 81;

fn int complement_code(i8 a_raw, i8 b_raw) {
    int a = (int)a_raw, b = (int)b_raw;
    int result = 0, place = 1;
    for (int feature = 0; feature < 4; feature++) {
        int digit_sum = (a / place) % 3 + (b / place) % 3;
        result += ((3 - digit_sum % 3) % 3) * place;
        place *= 3;
    }
    return result;
}

fn void put_i64_le(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[word * 8 + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long set_puzzle_find_sets(long* input, usz length, char* output,
        usz capacity) @export("set_puzzle_find_sets") {
    if (input == null || length < 1 || length > MAX_INPUT_WORDS) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > (long)MAX_CARDS || length != (usz)raw_count + 1) return -1;

    i8[DECK_SIZE] index_by_code;
    i8[MAX_CARDS] code_by_index;
    for (usz code = 0; code < DECK_SIZE; code++) index_by_code[code] = -1;
    usz count = (usz)raw_count;
    for (usz i = 0; i < count; i++) {
        long code = input[i + 1];
        if (code < 0 || code >= (long)DECK_SIZE || index_by_code[(usz)code] >= 0) return -1;
        index_by_code[(usz)code] = (i8)i;
        code_by_index[i] = (i8)code;
    }

    usz set_count = 0;
    for (usz i = 0; i < count; i++) {
        for (usz j = i + 1; j < count; j++) {
            int k = index_by_code[(usz)complement_code(code_by_index[i], code_by_index[j])];
            if (k > (int)j) set_count++;
        }
    }
    usz output_bytes = (1 + 3 * set_count) * 8;
    if (output == null || capacity < output_bytes) return -2;

    put_i64_le(output, 0, (long)set_count);
    usz word = 1;
    for (usz i = 0; i < count; i++) {
        for (usz j = i + 1; j < count; j++) {
            int k = index_by_code[(usz)complement_code(code_by_index[i], code_by_index[j])];
            if (k > (int)j) {
                put_i64_le(output, word++, (long)i);
                put_i64_le(output, word++, (long)j);
                put_i64_le(output, word++, (long)k);
            }
        }
    }
    return (long)output_bytes;
}
