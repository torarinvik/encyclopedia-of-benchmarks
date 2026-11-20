module bagwell_varray_growth_index;

const long MAX_N = 321;
const long MAX_Q = 256;
const usz DATA_SLOTS = 352;
const usz POINTER_SLOTS = 56;
const usz LEVEL_HEADERS = 3;

fn usz level_start(usz level) {
    if (level == 0) return 0;
    if (level == 1) return 64;
    return 320;
}

fn void locate(usz level, usz index, usz* pointer_slot, usz* child_base, usz* element_offset) {
    usz value_start = level == 0 ? 0 : level == 1 ? 64 : 320;
    usz side = level == 0 ? 8 : level == 1 ? 16 : 32;
    usz pointer_start = level == 0 ? 0 : level == 1 ? 8 : 24;
    usz data_start = value_start;
    usz relative = index - value_start;
    usz child = relative / side;
    *pointer_slot = pointer_start + child;
    *child_base = data_start + child * side;
    *element_offset = relative % side;
}

fn long find_level(usz index, usz current_header, long* previous_header) {
    long level = (long)current_header;
    while (level >= 0 && index < level_start((usz)level)) {
        level = previous_header[(usz)level];
    }
    return level;
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long bagwell_varray_growth_index(long* input, usz length, char* output,
                                    usz capacity) @export("bagwell_varray_growth_index") {
    if (input == null || length < 2 || length > 580) return -1;
    long n_value = input[0], q_value = input[1];
    if (n_value < 0 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    usz n = (usz)n_value, q = (usz)q_value;
    if ((n == 0 && q != 0) || length != 2 + n + q) return -1;
    usz query_start = 2 + n;
    for (usz j = 0; j < q; j++) {
        if (input[query_start + j] < 0 || input[query_start + j] >= n_value) return -1;
    }

    long[352] data = {0};
    long[56] pointers;
    long[3] previous_header = {-1, -1, -1};
    usz current_header = 0;
    for (usz i = 0; i < POINTER_SLOTS; i++) pointers[i] = -1;
    for (usz i = 0; i < n; i++) {
        if (i == 64 || i == 320) {
            usz next_header = current_header + 1;
            previous_header[next_header] = (long)current_header;
            current_header = next_header;
        }
        usz slot, base, offset;
        locate(current_header, i, &slot, &base, &offset);
        if (pointers[slot] == -1) pointers[slot] = (long)base;
        if (pointers[slot] != (long)base || base + offset >= DATA_SLOTS) return -1;
        data[(usz)pointers[slot] + offset] = input[2 + i];
    }

    usz output_bytes = 8 * (q + 1);
    if (output == null || capacity < output_bytes) return -2;
    put_i64_le(output, 0, q_value);
    for (usz j = 0; j < q; j++) {
        usz index = (usz)input[query_start + j];
        long level = find_level(index, current_header, &previous_header[0]);
        usz slot, base, offset;
        locate((usz)level, index, &slot, &base, &offset);
        put_i64_le(output, 8 * (j + 1), data[(usz)pointers[slot] + offset]);
    }
    return (long)output_bytes;
}
