module dynamicarray;

fn void write_word(char* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[word * 8 + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long dynamicarray(long* input, usz length, char* output, usz output_capacity) @export("dynamicarray") {
    if (input == null || length < 1 || length > 385 || input[0] < 0 || input[0] > 128) return -1;
    long[64] a; long[64] b; long[128] queries;
    usz size = 0;
    usz capacity = 0;
    usz cursor = 1;
    usz query_count = 0;
    usz active = 0;
    for (long oi = 0; oi < input[0]; oi++) {
        if (cursor >= length) return -1;
        long op = input[cursor++];
        if (op == 0) {
            if (cursor >= length || size >= 64) return -1;
            if (size == capacity) {
                if (active == 0) { for (usz i = 0; i < size; i++) b[i] = a[i]; active = 1; }
                else { for (usz i = 0; i < size; i++) a[i] = b[i]; active = 0; }
                capacity = capacity == 0 ? 10 : capacity * 2;
            }
            if (active == 0) { a[size] = input[cursor++]; } else { b[size] = input[cursor++]; }
            size++;
        } else if (op == 1) {
            if (cursor + 1 >= length) return -1;
            long index = input[cursor++];
            long value = input[cursor++];
            if (index < 0 || (ulong)index >= size) return -1;
            if (active == 0) { a[(usz)index] = value; } else { b[(usz)index] = value; }
        } else if (op == 2 || op == 3) {
            if (cursor >= length) return -1;
            long index = input[cursor++];
            if (index < 0 || (ulong)index >= size) return -1;
            usz at = (usz)index;
            if (op == 2) {
                if (query_count >= 128) return -1;
                queries[query_count++] = active == 0 ? a[at] : b[at];
            } else {
                if (active == 0) { for (usz i = at; i + 1 < size; i++) a[i] = a[i + 1]; }
                else { for (usz i = at; i + 1 < size; i++) b[i] = b[i + 1]; }
                size--;
            }
        } else if (op >= 4 && op <= 6) {
            if (query_count >= 128) return -1;
            queries[query_count++] = op == 4 ? (long)size : op == 5 ? (long)capacity : (size == 0 ? 1 : 0);
        } else { return -1; }
    }
    if (cursor != length) return -1;
    usz words = 3 + query_count + size;
    if (output == null || output_capacity < words * 8) return -2;
    write_word(output, 0, (long)query_count);
    for (usz i = 0; i < query_count; i++) write_word(output, i + 1, queries[i]);
    write_word(output, query_count + 1, (long)size);
    write_word(output, query_count + 2, (long)capacity);
    for (usz i = 0; i < size; i++) write_word(output, query_count + 3 + i, active == 0 ? a[i] : b[i]);
    return (long)words;
}
