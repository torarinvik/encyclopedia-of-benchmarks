module heaps_algorithm;

const long MAX_VALUES = 6;
const long BYTES_PER_VALUE = 8;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte += 1)
        output[offset + byte] = (char)(bits >> (8 * byte));
}

fn void emit_row(long* values, usz n, char* output, usz* rows) {
    usz row_offset = *rows * n * BYTES_PER_VALUE;
    for (usz index = 0; index < n; index += 1)
        store_i64_le(output, row_offset + index * BYTES_PER_VALUE, values[index]);
    *rows = *rows + 1;
}

fn void generate(long* values, usz n, usz k, char* output, usz* rows) {
    if (k == 1) {
        emit_row(values, n, output, rows);
        return;
    }
    generate(values, n, k - 1, output, rows);
    for (usz index = 0; index < k - 1; index += 1) {
        usz swap_index = if k % 2 == 0 then index else 0;
        long temporary = values[swap_index];
        values[swap_index] = values[k - 1];
        values[k - 1] = temporary;
        generate(values, n, k - 1, output, rows);
    }
}

fn long heaps_algorithm(long* values, usz length, char* output, usz capacity)
        @export("heaps_algorithm") {
    if (values == null || length < 1 || length > MAX_VALUES) return -1;
    usz row_count = 1;
    for (usz factor = 2; factor <= length; factor += 1) row_count *= factor;
    usz required = row_count * length * BYTES_PER_VALUE;
    if (output == null || capacity < required) return -2;
    long items[MAX_VALUES];
    for (usz index = 0; index < length; index += 1) items[index] = values[index];
    usz rows = 0;
    generate(&items[0], length, length, output, &rows);
    return (long)rows;
}
