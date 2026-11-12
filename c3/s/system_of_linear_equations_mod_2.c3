module system_of_linear_equations_mod_2

const usz MAX_N = 32;
const usz MAX_M = 32;
const usz MAX_INPUT_VALUES = 2 + MAX_N * MAX_M + MAX_N;

fn void store_u64_le(char* output, usz offset, ulong value) {
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(value & 255);
        value >>= 8;
    }
}

fn long system_of_linear_equations_mod_2(long* input, usz length,
    char* output, usz capacity) @export("system_of_linear_equations_mod_2") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || m_value < 1 || m_value > (long)MAX_M) return -1;
    usz n = (usz)n_value;
    usz m = (usz)m_value;
    if (length != 2 + n * m + n) return -1;

    ulong[MAX_N] rows;
    char[MAX_N] rhs;
    for (usz row = 0; row < MAX_N; row += 1) { rows[row] = 0; rhs[row] = 0; }
    for (usz row = 0; row < n; row += 1) {
        for (usz column = 0; column < m; column += 1) {
            long bit = input[2 + row * m + column];
            if (bit != 0 && bit != 1) return -1;
            rows[row] |= (ulong)bit << column;
        }
        long bit = input[2 + n * m + row];
        if (bit != 0 && bit != 1) return -1;
        rhs[row] = (char)bit;
    }

    usz[MAX_N] pivot_columns;
    for (usz row = 0; row < MAX_N; row += 1) pivot_columns[row] = 0;
    usz pivot_row = 0;
    for (usz column = 0; column < m; column += 1) {
        usz pivot = pivot_row;
        while (pivot < n && ((rows[pivot] >> column) & 1) == 0) pivot += 1;
        if (pivot == n) continue;
        ulong row_temporary = rows[pivot_row];
        rows[pivot_row] = rows[pivot];
        rows[pivot] = row_temporary;
        char rhs_temporary = rhs[pivot_row];
        rhs[pivot_row] = rhs[pivot];
        rhs[pivot] = rhs_temporary;
        for (usz row = 0; row < n; row += 1) {
            if (row != pivot_row && ((rows[row] >> column) & 1) != 0) {
                rows[row] ^= rows[pivot_row];
                rhs[row] ^= rhs[pivot_row];
            }
        }
        pivot_columns[pivot_row] = column;
        pivot_row += 1;
    }

    for (usz row = pivot_row; row < n; row += 1) {
        if (rows[row] == 0 && rhs[row] != 0) {
            if (output == null || capacity < 8) return -2;
            store_u64_le(output, 0, 0xffffffffffffffff);
            return 8;
        }
    }

    bool[MAX_M] is_pivot;
    for (usz column = 0; column < MAX_M; column += 1) is_pivot[column] = false;
    for (usz row = 0; row < pivot_row; row += 1) is_pivot[pivot_columns[row]] = true;
    usz nullity = m - pivot_row;
    usz output_bytes = 8 * (nullity + 2);
    if (output == null || capacity < output_bytes) return -2;

    ulong particular = 0;
    for (usz row = 0; row < pivot_row; row += 1)
        if (rhs[row] != 0) particular |= 1ul << pivot_columns[row];
    store_u64_le(output, 0, (ulong)nullity);
    store_u64_le(output, 8, particular);
    usz basis_index = 0;
    for (usz free_column = 0; free_column < m; free_column += 1) {
        if (is_pivot[free_column]) continue;
        ulong basis = 1ul << free_column;
        for (usz row = 0; row < pivot_row; row += 1)
            if (((rows[row] >> free_column) & 1) != 0)
                basis |= 1ul << pivot_columns[row];
        store_u64_le(output, 16 + 8 * basis_index, basis);
        basis_index += 1;
    }
    return (long)output_bytes;
}
