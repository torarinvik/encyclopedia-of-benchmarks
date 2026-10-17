module sequence;

const long MAX_COUNT = 64;
const usz MAX_PARSEABLE_INPUT_LENGTH = 3;
const usz MAX_OUTPUT_BYTES = 8 * 64;

fn long generate_nth_term(long index) {
    if (index == 0 || index == 1) return index;
    if (index % 2 == 0) return 4 * generate_nth_term(index / 2);
    return 4 * generate_nth_term(index / 2) + 1;
}

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long sequence(long* values, usz length, char* output, usz output_capacity)
        @export("sequence") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (length != 1 || values[0] < -MAX_COUNT || values[0] > MAX_COUNT) return -1;
    if (values[0] <= 0) return 0;

    usz count = (usz)values[0];
    usz required = count * 8;
    if (output == null || output_capacity < required || required > MAX_OUTPUT_BYTES) return -2;
    for (usz index = 0; index < count; index++)
        put_i64_le(generate_nth_term((long)index), output, index * 8);
    return (long)required;
}
