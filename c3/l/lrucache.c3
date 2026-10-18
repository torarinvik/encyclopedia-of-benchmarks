module lrucache;

const usz MAX_CAPACITY = 16;
const usz MAX_OPERATIONS = 32;
const usz MAX_INPUT_LENGTH = 99;
const usz MAX_OUTPUT_WORDS = 130;

fn long lrucache(long* input, usz input_length, uint8* output, usz output_capacity)
    @export("lrucache") {
    if (input == null || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1L;
    long capacity_value = input[0];
    long operation_count_value = input[1];
    if (capacity_value < 2 || capacity_value > (long)MAX_CAPACITY ||
        operation_count_value < 0 || operation_count_value > (long)MAX_OPERATIONS) return -1L;
    usz capacity = (usz)capacity_value;
    usz operation_count = (usz)operation_count_value;
    if (input_length != 2 + 3 * operation_count) return -1L;

    long[MAX_CAPACITY] keys = zeroed;
    long[MAX_CAPACITY] cached_values = zeroed;
    long[MAX_OPERATIONS] seen_put_keys = zeroed;
    long[3 * MAX_OPERATIONS] operation_records = zeroed;
    usz used = 0;
    usz seen_count = 0;

    for (usz operation = 0; operation < operation_count; operation++) {
        long opcode = input[2 + 3 * operation];
        long key = input[3 + 3 * operation];
        long value = input[4 + 3 * operation];
        if (opcode != 0 && opcode != 1) return -1L;
        if (key < 0 || key > 1000000) return -1L;

        long returned_value = -1;
        long evicted_key = -1;
        usz position = 0;
        while (position < used && keys[position] != key) position++;

        if (opcode == 0) {
            if (value < 0 || value > 1000000) return -1L;
            for (usz prior = 0; prior < seen_count; prior++)
                if (seen_put_keys[prior] == key) return -1L;
            seen_put_keys[seen_count++] = key;
            if (used == capacity) {
                evicted_key = keys[0];
                for (usz index = 1; index < used; index++) {
                    keys[index - 1] = keys[index];
                    cached_values[index - 1] = cached_values[index];
                }
                used--;
            }
            keys[used] = key;
            cached_values[used] = value;
            used++;
        } else {
            if (value != 0 || position == used) return -1L;
            returned_value = cached_values[position];
            for (usz index = position + 1; index < used; index++) {
                keys[index - 1] = keys[index];
                cached_values[index - 1] = cached_values[index];
            }
            keys[used - 1] = key;
            cached_values[used - 1] = returned_value;
        }
        operation_records[3 * operation] = opcode;
        operation_records[3 * operation + 1] = returned_value;
        operation_records[3 * operation + 2] = evicted_key;
    }

    long[MAX_OUTPUT_WORDS] fields = zeroed;
    usz word_count = 0;
    fields[word_count++] = operation_count_value;
    for (usz index = 0; index < 3 * operation_count; index++)
        fields[word_count++] = operation_records[index];
    fields[word_count++] = (long)used;
    for (usz index = used; index > 0; index--) {
        fields[word_count++] = keys[index - 1];
        fields[word_count++] = cached_values[index - 1];
    }

    usz output_bytes = word_count * 8;
    if (output == null || output_capacity < output_bytes) return -2L;
    for (usz index = 0; index < word_count; index++) {
        ulong bits = (ulong)fields[index];
        for (usz byte = 0; byte < 8; byte++) {
            output[index * 8 + byte] = (uint8)(bits & 255);
            bits >>= 8;
        }
    }
    return (long)output_bytes;
}
