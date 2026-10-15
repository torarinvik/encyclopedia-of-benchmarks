module alternative_list_arrange;

fn void store_i64_le(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long alternative_list_arrange(long* input, usz length, char* output, usz output_capacity) @export("alternative_list_arrange") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 64) return -1;
    usz a = (usz)input[0];
    if (1 + a >= length || input[1 + a] < 0 || input[1 + a] > 64) return -1;
    usz b = (usz)input[1 + a];
    if (length != 2 + a + b) return -1;
    usz count = a + b;
    if (count == 0) return 0;
    usz bytes = count * 8;
    if (output == null || output_capacity < bytes) return -2;
    usz written = 0;
    for (usz i = 0; i < a || i < b; i++) {
        if (i < a) { store_i64_le(input[1 + i], output, written * 8); written++; }
        if (i < b) { store_i64_le(input[2 + a + i], output, written * 8); written++; }
    }
    return (long)count;
}
