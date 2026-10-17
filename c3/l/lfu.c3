module lfu;

const usz MIN_CAPACITY = 2;
const usz MAX_CAPACITY = 16;
const usz MAX_OPERATIONS = 32;
const usz MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS;
const usz MAX_OUTPUT_WORDS = 3 * MAX_OPERATIONS;

fn void append(long* words, usz* count, long value) {
    words[*count] = value;
    *count += 1;
}

fn void move_to_front(long* keys, long* values, usz index) {
    long key = keys[index];
    long value = values[index];
    for (usz i = index; i > 0; i--) {
        keys[i] = keys[i - 1];
        values[i] = values[i - 1];
    }
    keys[0] = key;
    values[0] = value;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long lfu(long* input, usz length, char* output, usz output_capacity)
        @export("lfu") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < (long)MIN_CAPACITY || input[0] > (long)MAX_CAPACITY ||
        input[1] < 0 || input[1] > (long)MAX_OPERATIONS) return -1;

    usz cache_capacity = (usz)input[0];
    usz operation_count = (usz)input[1];
    long[16] keys = {0};
    long[16] values = {0};
    usz size = 0;
    long[MAX_OUTPUT_WORDS] words = {0};
    usz word_count = 0;
    usz position = 2;

    for (usz operation = 0; operation < operation_count; operation++) {
        if (position >= length) return -1;
        long opcode = input[position++];
        if (opcode == 0) {
            if (position + 1 >= length) return -1;
            long key_arg = input[position++];
            long value_arg = input[position++];
            if (key_arg < -2147483648 || key_arg > 2147483647 ||
                value_arg < -2147483648 || value_arg > 2147483647) return -1;
            usz index = 0;
            while (index < size && keys[index] != key_arg) index++;
            if (index < size) {
                // The pinned Put mutates a copied item; the old value remains.
                move_to_front(keys, values, index);
            } else {
                if (size == cache_capacity) size--;
                for (usz i = size; i > 0; i--) {
                    keys[i] = keys[i - 1];
                    values[i] = values[i - 1];
                }
                keys[0] = key_arg;
                values[0] = value_arg;
                size++;
            }
            append(words, &word_count, 0);
        } else if (opcode == 1) {
            if (position >= length) return -1;
            long key_arg = input[position++];
            if (key_arg < -2147483648 || key_arg > 2147483647) return -1;
            usz index = 0;
            while (index < size && keys[index] != key_arg) index++;
            append(words, &word_count, 1);
            if (index == size) {
                append(words, &word_count, 1);
                append(words, &word_count, 0);
            } else {
                long value = values[index];
                move_to_front(keys, values, index);
                append(words, &word_count, 0);
                append(words, &word_count, value);
            }
        } else {
            return -1;
        }
    }
    if (position != length || word_count > MAX_OUTPUT_WORDS) return -1;
    usz output_length = word_count * 8;
    if (output == null || output_capacity < output_length) return -2;
    for (usz i = 0; i < word_count; i++) put_i64_le(output, i * 8, words[i]);
    return (long)output_length;
}
