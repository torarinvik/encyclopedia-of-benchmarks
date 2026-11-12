module matrix_det_mod_2;

const usz MAX_N = 64;
const usz MAX_INPUT_VALUES = 1 + MAX_N * MAX_N;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long matrix_det_mod_2(long* input, usz length, char* output, usz capacity)
    @export("matrix_det_mod_2") {
    if (input == null || length < 1 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + n * n) return -1;

    ulong[MAX_N] rows;
    for (usz row = 0; row < MAX_N; row += 1) rows[row] = 0;
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < n; column += 1) {
            long bit = input[1 + row * n + column];
            if (bit != 0 && bit != 1) return -1;
            rows[row] |= ((ulong)bit) << column;
        }
    }

    usz pivot_row = 0;
    for (usz column = 0; column < n; column += 1) {
        usz pivot = pivot_row;
        while (pivot < n && ((rows[pivot] >> column) & 1) == 0) pivot += 1;
        if (pivot == n) continue;
        ulong temporary = rows[pivot_row];
        rows[pivot_row] = rows[pivot];
        rows[pivot] = temporary;
        for (usz row = pivot_row + 1; row < n; row += 1)
            if (((rows[row] >> column) & 1) != 0) rows[row] ^= rows[pivot_row];
        pivot_row += 1;
    }
    if (output == null || capacity < 8) return -2;
    long result = 0;
    if (pivot_row == n) result = 1;
    store_i64_le(output, result);
    return 8;
}
