module reverse_stack;

const long MAX_ELEMENTS = 16;

fn void insert_at_bottom(long* items, usz size, long value) {
    if (size == 0) { items[0] = value; return; }
    long top = items[size - 1];
    insert_at_bottom(items, size - 1, value);
    items[size] = top;
}

fn void reverse_recursive(long* items, usz size) {
    if (size == 0) return;
    long top = items[size - 1];
    reverse_recursive(items, size - 1);
    insert_at_bottom(items, size - 1, top);
}

fn void put_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long reverse_stack(long* input, usz length, char* output, usz capacity) @export("reverse_stack") {
    if (input == null || length < 1) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_ELEMENTS || length != (usz)raw_count + 1) return -1;
    usz count = (usz)raw_count;
    long[MAX_ELEMENTS] items;
    for (usz i = 0; i < count; i += 1) {
        if (input[i + 1] < -1000000 || input[i + 1] > 1000000) return -1;
        items[i] = input[i + 1];
    }
    usz bytes = (count + 1) * 8;
    if (output == null || capacity < bytes) return -2;
    reverse_recursive(&items[0], count);
    put_i64_le(output, 0, raw_count);
    for (usz i = 0; i < count; i += 1) put_i64_le(output, 8 * (i + 1), items[i]);
    return (long)bytes;
}
