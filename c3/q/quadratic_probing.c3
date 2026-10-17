module quadratic_probing;

const long MIN_CAPACITY = 5;
const long MAX_CAPACITY = 31;
const long MAX_INSERT_COUNT = 3;
const usz MAX_PARSEABLE_INPUT_LENGTH = 5;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = @bitcast(ulong, value);
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long quadratic_probing(long* input, usz input_length, char* output, usz output_capacity)
    @export("quadratic_probing")
{
    if (input == null || input_length < 2 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;

    long capacity_value = input[0];
    long insert_count_value = input[1];
    if (capacity_value < MIN_CAPACITY || capacity_value > MAX_CAPACITY ||
        insert_count_value < 0 || insert_count_value > MAX_INSERT_COUNT) return -1;

    usz capacity = (usz)capacity_value;
    usz insert_count = (usz)insert_count_value;
    if (input_length != 2 + insert_count) return -1;

    for (usz i = 0; i < insert_count; i++) {
        if (input[2 + i] < 0) return -1;
    }

    long[MAX_CAPACITY] table;
    for (usz slot = 0; slot < capacity; slot++) table[slot] = -1;

    for (usz i = 0; i < insert_count; i++) {
        long data = input[2 + i];
        usz home = (usz)(data % (long)capacity);
        if (table[home] == -1) {
            table[home] = data;
            continue;
        }
        if (table[home] == data) continue;

        usz probe = 1;
        usz slot = (home + probe * probe) % capacity;
        while (table[slot] != -1 && table[slot] != (long)home) {
            probe++;
            slot = (home + probe * probe) % capacity;
        }
        table[slot] = data;
    }

    usz output_bytes = 8 * (capacity + 1);
    if (output == null || output_capacity < output_bytes) return -2;
    write_i64_le(output, 0, (long)capacity);
    for (usz slot = 0; slot < capacity; slot++) {
        write_i64_le(output, 8 * (slot + 1), table[slot]);
    }
    return (long)output_bytes;
}
