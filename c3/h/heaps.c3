module heaps;

const long MAX_N = 7;

fn void emit_row(u8* items, usz n, char* output, usz* rows) {
    usz offset = *rows * n;
    for (usz index = 0; index < n; index += 1) output[offset + index] = (char)items[index];
    *rows = *rows + 1;
}

fn void generate(u8* items, usz n, usz size, char* output, usz* rows) {
    if (size == 1) {
        emit_row(items, n, output, rows);
        return;
    }
    for (usz index = 0; index < size; index += 1) {
        generate(items, n, size - 1, output, rows);
        usz swap_index = if size % 2 == 1 then index else 0;
        u8 temporary = items[swap_index];
        items[swap_index] = items[size - 1];
        items[size - 1] = temporary;
    }
}

fn long heaps(long* values, usz length, char* output, usz capacity) @export("heaps") {
    if (values == null || length != 1 || values[0] < 0 || values[0] > MAX_N) return -1;
    usz n = (usz)values[0];
    if (n == 0) return 0;
    usz row_count = 1;
    for (usz factor = 2; factor <= n; factor += 1) row_count *= factor;
    usz required = row_count * n;
    if (output == null || capacity < required) return -2;
    u8 items[MAX_N];
    for (usz index = 0; index < n; index += 1) items[index] = (u8)(49 + index);
    usz rows = 0;
    generate(&items[0], n, n, output, &rows);
    return (long)rows;
}
