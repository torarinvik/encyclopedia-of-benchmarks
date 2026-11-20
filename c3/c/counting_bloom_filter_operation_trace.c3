module counting_bloom_filter_operation_trace;

const usz MAX_OPERATIONS = 64;
const usz MAX_PARSEABLE_LENGTH = 130;
const usz COUNTER_COUNT = 67;
const usz HASH_COUNT = 4;

fn void hash_positions(long key, usz* positions) {
    long first = (17 * key + 3) % (long)COUNTER_COUNT;
    long step = 1 + ((5 * key + 3) % ((long)COUNTER_COUNT - 1));
    for (usz index = 0; index < HASH_COUNT; index += 1)
        positions[index] = (usz)((first + (long)index * step) % (long)COUNTER_COUNT);
}

fn long counting_bloom_filter_operation_trace(
    long* input, usz length, char* output, usz output_capacity)
    @export("counting_bloom_filter_operation_trace") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    long q_value = input[0];
    if (q_value < 0 || q_value > (long)MAX_OPERATIONS) return -1;
    usz q = (usz)q_value;
    if (length != 1 + 2 * q) return -1;

    for (usz operation_index = 0; operation_index < q; operation_index += 1) {
        long opcode = input[1 + 2 * operation_index];
        long key = input[2 + 2 * operation_index];
        if (opcode < 0 || opcode > 2 || key < 0 || key > 65535) return -1;
    }
    if (output == null || output_capacity < q) return -2;

    long[COUNTER_COUNT] counters;
    for (usz index = 0; index < COUNTER_COUNT; index += 1) counters[index] = 0;

    for (usz operation_index = 0; operation_index < q; operation_index += 1) {
        long opcode = input[1 + 2 * operation_index];
        long key = input[2 + 2 * operation_index];
        usz[HASH_COUNT] positions;
        hash_positions(key, &positions[0]);

        if (opcode == 0) {
            for (usz hash = 0; hash < HASH_COUNT; hash += 1)
                counters[positions[hash]] += 1;
            output[operation_index] = (char)1;
        } else if (opcode == 1) {
            // The caller supplies only deletes of currently represented keys.
            for (usz hash = 0; hash < HASH_COUNT; hash += 1)
                counters[positions[hash]] -= 1;
            output[operation_index] = (char)1;
        } else {
            bool present = true;
            for (usz hash = 0; hash < HASH_COUNT; hash += 1)
                if (counters[positions[hash]] == 0) present = false;
            output[operation_index] = (char)(present ? 1 : 0);
        }
    }
    return (long)q;
}
