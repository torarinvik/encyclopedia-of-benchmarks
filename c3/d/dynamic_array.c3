module dynamic_array;

const usz MAX_OPERATIONS = 128;
const usz MAX_ELEMENTS = 64;
const usz MAX_INPUT_LENGTH = 385;

fn void write_i64_le(char* output, usz word_index, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[word_index * 8 + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long dynamic_array(long* input, usz length, char* output, usz output_capacity) @export("dynamic_array") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) { return -1; }
    long operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > 128) { return -1; }

    long[MAX_ELEMENTS] first;
    long[MAX_ELEMENTS] second;
    long[MAX_OPERATIONS] query_results;
    usz active = 0;
    usz size = 0;
    usz capacity = 16;
    usz cursor = 1;
    usz query_count = 0;

    for (long operation_index = 0; operation_index < operation_count_value; operation_index++) {
        if (cursor >= length) { return -1; }
        long operation = input[cursor];
        cursor++;
        if (operation == 0) {
            if (cursor >= length || size >= MAX_ELEMENTS) { return -1; }
            long value = input[cursor];
            cursor++;
            if (size == capacity) {
                if (active == 0) {
                    for (usz index = 0; index < size; index++) { second[index] = first[index]; }
                    active = 1;
                } else {
                    for (usz index = 0; index < size; index++) { first[index] = second[index]; }
                    active = 0;
                }
                capacity *= 2;
            }
            if (active == 0) { first[size] = value; }
            else { second[size] = value; }
            size++;
        } else if (operation == 1) {
            if (cursor + 1 >= length) { return -1; }
            long index_value = input[cursor];
            long value = input[cursor + 1];
            cursor += 2;
            if (index_value < 0 || index_value >= (long)size) { return -1; }
            if (active == 0) { first[(usz)index_value] = value; }
            else { second[(usz)index_value] = value; }
        } else if (operation == 2) {
            if (cursor >= length || query_count >= MAX_OPERATIONS) { return -1; }
            long index_value = input[cursor];
            cursor++;
            if (index_value < 0 || index_value >= (long)size) { return -1; }
            if (active == 0) { query_results[query_count] = first[(usz)index_value]; }
            else { query_results[query_count] = second[(usz)index_value]; }
            query_count++;
        } else if (operation == 3) {
            if (query_count >= MAX_OPERATIONS) { return -1; }
            query_results[query_count] = (long)size;
            query_count++;
        } else {
            return -1;
        }
    }
    if (cursor != length) { return -1; }

    usz output_words = 2 + query_count + size;
    usz output_bytes = output_words * 8;
    if (output == null || output_capacity < output_bytes) { return -2; }
    write_i64_le(output, 0, (long)query_count);
    for (usz index = 0; index < query_count; index++) {
        write_i64_le(output, index + 1, query_results[index]);
    }
    write_i64_le(output, query_count + 1, (long)size);
    for (usz index = 0; index < size; index++) {
        long value = first[index];
        if (active != 0) { value = second[index]; }
        write_i64_le(output, query_count + 2 + index, value);
    }
    (long)output_words
}
