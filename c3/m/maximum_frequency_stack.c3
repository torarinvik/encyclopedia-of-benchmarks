module maximum_frequency_stack;

fn void store_i64(char *out, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { out[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long maximum_frequency_stack(long *input, usz length, char *output, usz capacity) @export("maximum_frequency_stack") {
    if (input == null || length < 1 || length > 130) return -1;
    long count = input[0];
    if (count < 0 || count > 64 || length != 1 + 2 * (usz)count) return -1;
    int frequency[17]; int bucket_top[65];
    for (usz i = 0; i < 17; i++) frequency[i] = 0;
    for (usz i = 0; i < 65; i++) bucket_top[i] = -1;
    int node_value[64]; int node_next[64]; long popped[64];
    usz nodes = 0, pop_count = 0, position = 1; int maximum_frequency = 0;
    for (long operation = 0; operation < count; operation++) {
        long opcode = input[position++], argument = input[position++];
        if (opcode == 0) {
            if (argument < -8 || argument > 8) return -1;
            int index = (int)argument + 8, level = ++frequency[index];
            node_value[nodes] = (int)argument; node_next[nodes] = bucket_top[level];
            bucket_top[level] = (int)nodes++;
            if (level > maximum_frequency) maximum_frequency = level;
        } else if (opcode == 1 && argument == 0) {
            if (maximum_frequency == 0 || bucket_top[maximum_frequency] < 0) return -1;
            int node = bucket_top[maximum_frequency]; bucket_top[maximum_frequency] = node_next[node];
            int value = node_value[node]; popped[pop_count++] = value; frequency[value + 8]--;
            if (bucket_top[maximum_frequency] < 0) maximum_frequency--;
        } else return -1;
    }
    usz needed = pop_count * 8;
    if (needed != 0 && (output == null || capacity < needed)) return -2;
    for (usz i = 0; i < pop_count; i++) store_i64(output, i * 8, popped[i]);
    return (long)needed;
}
