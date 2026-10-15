module quartile;

fn void store_i64_le(long value, char* output, usz position) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[position + byte] = (char)(bits & 255); bits >>= 8; }
}

// Sort up to ten bounded values and encode quartile statistics.
fn long quartile(long* input, usz length, char* output, usz output_capacity)
        @export("quartile") {
    if (input == null || length < 2 || length > 11) return -1;
    if (input[0] < 1 || input[0] > 10 || length != (usz)input[0] + 1) return -1;
    usz count = (usz)input[0];
    long[10] values;
    for (usz i = 0; i < count; i++) {
        if (input[i + 1] < 0 || input[i + 1] > 99) return -1;
        values[i] = input[i + 1];
    }
    for (usz i = 0; i < count; i++) for (usz j = 0; j < count; j++) {
        if (values[i] < values[j]) { long tmp = values[i]; values[i] = values[j]; values[j] = tmp; }
    }
    long q1 = values[count / 4];
    long q3 = values[(3 * count) / 4];
    usz required = (count + 4) * 8;
    if (output == null || output_capacity < required) return -2;
    store_i64_le((long)count, output, 0);
    for (usz i = 0; i < count; i++) store_i64_le(values[i], output, 8 * (i + 1));
    store_i64_le(q1, output, 8 * (count + 1));
    store_i64_le(q3, output, 8 * (count + 2));
    store_i64_le(q3 - q1, output, 8 * (count + 3));
    return (long)required;
}
