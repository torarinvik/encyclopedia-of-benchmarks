module count_min_sketch_width_one_collision;

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long count_min_sketch_width_one_collision(long* input, usz length, char* output, usz capacity)
    @export("count_min_sketch_width_one_collision") {
    if (input == null || length < 1 || length > 513) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > 256 || length != 1 + (usz)count_value * 2) return -1;
    usz count = (usz)count_value, queries = 0;
    for (usz i = 0; i < count; i++) {
        long operation = input[1 + 2 * i], key = input[2 + 2 * i];
        if ((operation != 0 && operation != 1) || key < -1000000 || key > 1000000) return -1;
        if (operation == 1) queries++;
    }
    usz required = queries * 8;
    if (capacity < required || (required > 0 && output == null)) return -2;
    long inserts = 0;
    usz output_offset = 0;
    for (usz i = 0; i < count; i++) {
        if (input[1 + 2 * i] == 0) inserts++;
        else { put_i64_le(output, output_offset, inserts); output_offset += 8; }
    }
    return (long)required;
}
