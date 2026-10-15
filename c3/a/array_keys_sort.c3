module array_keys_sort;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}
fn int compare_rows(long* left, long* right, long* keys, usz key_count, bool ascending) {
    for (usz key = 0; key < key_count; key += 1) {
        long a = left[(usz)(keys[key] - 1)], b = right[(usz)(keys[key] - 1)];
        if (a < b) return ascending ? -1 : 1;
        if (a > b) return ascending ? 1 : -1;
    }
    return 0;
}
fn long array_keys_sort(long* values, usz length, char* output, usz capacity) @export("array_keys_sort") {
    if (values == null || length < 8 || length > 263) return -1;
    long raw_count = values[0], raw_key_count = values[1], order = values[2];
    if (raw_count < 1 || raw_count > 64 || raw_key_count < 1 || raw_key_count > 4 || (order != 0 && order != 1)) return -1;
    usz count = (usz)raw_count, key_count = (usz)raw_key_count;
    if (length != 3 + key_count + 4 * count) return -1;
    long* keys = &values[3];
    for (usz i = 0; i < key_count; i += 1) {
        if (keys[i] < 1 || keys[i] > 4) return -1;
        for (usz j = 0; j < i; j += 1) if (keys[i] == keys[j]) return -1;
    }
    long[256] rows;
    usz rows_start = 3 + key_count;
    for (usz i = 0; i < 4 * count; i += 1) {
        long value = values[rows_start + i];
        if (value < -1000 || value > 1000) return -1;
        rows[i] = value;
    }
    for (usz i = 0; i < count; i += 1) for (usz j = i + 1; j < count; j += 1)
        if (compare_rows(&rows[i * 4], &rows[j * 4], keys, key_count, true) == 0) return -1;
    usz byte_count = 32 * count;
    if (output == null || capacity < byte_count) return -2;
    for (usz i = 1; i < count; i += 1) {
        long[4] temporary;
        for (usz column = 0; column < 4; column += 1) temporary[column] = rows[i * 4 + column];
        usz position = i;
        while (position > 0 && compare_rows(&rows[(position - 1) * 4], &temporary[0], keys, key_count, order == 1) > 0) {
            for (usz column = 0; column < 4; column += 1) rows[position * 4 + column] = rows[(position - 1) * 4 + column];
            position -= 1;
        }
        for (usz column = 0; column < 4; column += 1) rows[position * 4 + column] = temporary[column];
    }
    for (usz i = 0; i < 4 * count; i += 1) store_i64_le(output, 8 * i, rows[i]);
    return (long)byte_count;
}
