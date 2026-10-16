module xor_linked_list;

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long xor_linked_list(long* input, usz length, char* output, usz capacity) @export("xor_linked_list") {
    if (input == null || length < 1 || length > 66) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > 64) return -1;
    usz count = (usz)count_value;
    if (length != count + 1) return -1;
    for (usz i = 0; i < count; i++) {
        if (input[i + 1] < -2147483648L || input[i + 1] > 2147483647L) return -1;
    }
    usz needed = 8 + 8 * count;
    if (output == null || capacity < needed) return -2;

    long node_values[65] = {0};
    usz both[65] = {0};
    usz tail = 0;
    for (usz i = 0; i < count; i++) {
        usz node_id = i + 1;
        node_values[node_id] = input[i + 1];
        both[node_id] = tail;
        if (tail != 0) both[tail] ^= node_id;
        tail = node_id;
    }
    write_i64_le(output, 0, count_value);
    usz out = 8, previous = 0, current = count == 0 ? 0 : 1;
    while (current != 0) {
        write_i64_le(output, out, node_values[current]);
        out += 8;
        usz next = previous ^ both[current];
        previous = current;
        current = next;
    }
    return (long)needed;
}
