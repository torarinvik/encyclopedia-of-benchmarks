module least_recently_used;

fn void put_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits >> (8 * byte)); }
}

fn long least_recently_used(long* input, usz length, uint8* output, usz output_capacity) @export("least_recently_used") {
    if (input == null || length < 2 || length > 66) { return -1; }
    long capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > 16 || count_value < 0 || count_value > 64) { return -1; }
    usz cache_capacity = (usz)capacity_value, references = (usz)count_value;
    if (length != 2 + references) { return -1; }
    for (usz i = 0; i < references; i++) {
        if (input[2 + i] < -2147483648 || input[2 + i] > 2147483647) { return -1; }
    }

    long[16] keys = zeroed;
    usz count = 0;
    for (usz i = 0; i < references; i++) {
        long key = input[2 + i];
        usz found = count;
        for (usz j = 0; j < count; j++) { if (keys[j] == key) { found = j; break; } }
        if (found < count) {
            for (usz j = found; j + 1 < count; j++) { keys[j] = keys[j + 1]; }
            count--;
        } else if (count == cache_capacity) { count--; }
        usz j = count;
        while (j > 0) { keys[j] = keys[j - 1]; j--; }
        keys[0] = key;
        count++;
    }

    usz elements = count + 1, required = elements * 8;
    if (output == null || output_capacity < required) { return -2; }
    put_i64_le(output, 0, (long)count);
    for (usz i = 0; i < count; i++) { put_i64_le(output, 8 * (i + 1), keys[i]); }
    return (long)elements;
}
