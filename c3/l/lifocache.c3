module lifocache;

fn void put_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) { output[offset + i] = (uint8)(bits >> (8 * i)); }
}

fn long lifocache(long* input, usz length, uint8* output, usz output_capacity) @export("lifocache") {
    if (input == null || length < 2 || length > 194) { return -1; }
    long capacity_value = input[0], operation_count_value = input[1];
    if (capacity_value < 1 || capacity_value > 16 || operation_count_value < 1 || operation_count_value > 64) { return -1; }
    usz capacity = (usz)capacity_value, operations = (usz)operation_count_value;
    if (length != 2 + 3 * operations) { return -1; }
    for (usz i = 0; i < operations; i++) {
        long op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        if (op < 0 || op > 6) { return -1; }
        if (op <= 2) {
            if (key < -2147483648 || key > 2147483647) { return -1; }
            if (op == 0) { if (value < -2147483648 || value > 2147483647) { return -1; } }
            else if (value != 0) { return -1; }
        } else if (key != 0 || value != 0) { return -1; }
    }
    usz required = operations * 16;
    if (output == null || output_capacity < required) { return -2; }
    long[16] keys = {0};
    long[16] values = {0};
    usz count = 0;
    long hits = 0, misses = 0;
    for (usz i = 0; i < operations; i++) {
        long op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        long first = 0, second = 0;
        if (op == 0) {
            usz found = count;
            for (usz j = 0; j < count; j++) { if (keys[j] == key) { found = j; break; } }
            if (found < count) { for (usz j = found; j + 1 < count; j++) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; } count--; }
            if (count == capacity) { count--; }
            keys[count] = key; values[count] = value; count++;
            first = 1;
        } else if (op == 1) {
            usz found = count;
            for (usz j = 0; j < count; j++) { if (keys[j] == key) { found = j; break; } }
            if (found < count) { hits++; first = 1; second = values[found]; } else { misses++; }
        } else if (op == 2) {
            usz found = count;
            for (usz j = 0; j < count; j++) { if (keys[j] == key) { found = j; break; } }
            if (found < count) { first = 1; second = values[found]; for (usz j = found; j + 1 < count; j++) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; } count--; }
        } else if (op == 3) { first = (long)count; }
        else if (op == 4) { first = hits; }
        else if (op == 5) { first = misses; }
        else { count = 0; hits = 0; misses = 0; first = 1; }
        put_i64_le(output, 16 * i, first); put_i64_le(output, 16 * i + 8, second);
    }
    return (long)(2 * operations);
}
