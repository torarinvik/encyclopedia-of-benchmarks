module stormer_verlet_position;

const long MAX_STEPS = 32;
const usz MAX_INPUT_VALUES = 33;
const usz MAX_OUTPUT_BYTES = 256;

fn void store_i64_le(uint8[MAX_OUTPUT_BYTES]* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        (*output)[offset + byte] = (uint8)((bits >> (8 * byte)) & 255);
}

fn long stormer_verlet_position(long* input, usz length, uint8* output,
                                usz output_capacity) @export("stormer_verlet_position") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES) return -1;
    long count_value = input[0];
    if (count_value < 2 || count_value > MAX_STEPS) return -1;
    if (length != (usz)count_value + 1) return -1;
    if (input[1] < -1024 || input[1] > 1024 || input[2] < -1024 || input[2] > 1024) return -1;
    usz count = (usz)count_value;
    for (usz step = 0; step < count - 2; step++)
        if (input[3 + step] < -64 || input[3 + step] > 64) return -1;

    usz byte_count = 8 * count;
    if (output == null || output_capacity < byte_count) return -2;
    uint8[MAX_OUTPUT_BYTES] staged = zeroed;
    long previous = input[1], current = input[2];
    store_i64_le(&staged, 0, previous);
    store_i64_le(&staged, 8, current);
    for (usz index = 2; index < count; index++) {
        long next = 2 * current - previous + input[index + 1];
        store_i64_le(&staged, 8 * index, next);
        previous = current;
        current = next;
    }
    for (usz byte = 0; byte < byte_count; byte++) output[byte] = staged[byte];
    return (long)byte_count;
}
