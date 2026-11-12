module matrix_product_mod_2;

const usz MAX_DIMENSION = 64;
const usz MAX_INPUT_VALUES = 3 + 2 * MAX_DIMENSION * MAX_DIMENSION;
const usz MAX_OUTPUT_VALUES = MAX_DIMENSION * MAX_DIMENSION;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long matrix_product_mod_2(long* input, usz length, char* output, usz capacity)
    @export("matrix_product_mod_2") {
    if (input == null || length < 3 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], m_value = input[1], k_value = input[2];
    if (n_value < 1 || n_value > (long)MAX_DIMENSION || m_value < 1 ||
        m_value > (long)MAX_DIMENSION || k_value < 1 || k_value > (long)MAX_DIMENSION) return -1;
    usz n = (usz)n_value, m = (usz)m_value, k = (usz)k_value;
    usz a_length = n * m, b_length = m * k;
    if (length != 3 + a_length + b_length) return -1;

    ulong[MAX_DIMENSION] packed_b;
    for (usz inner = 0; inner < MAX_DIMENSION; inner += 1) packed_b[inner] = 0;
    usz b_start = 3 + a_length;
    for (usz inner = 0; inner < m; inner += 1) {
        for (usz column = 0; column < k; column += 1) {
            long bit = input[b_start + inner * k + column];
            if (bit != 0 && bit != 1) return -1;
            packed_b[inner] |= ((ulong)bit) << column;
        }
    }

    long[MAX_OUTPUT_VALUES] staged;
    for (usz row = 0; row < n; row += 1) {
        ulong accumulator = 0;
        for (usz inner = 0; inner < m; inner += 1) {
            long bit = input[3 + row * m + inner];
            if (bit != 0 && bit != 1) return -1;
            if (bit == 1) accumulator ^= packed_b[inner];
        }
        for (usz column = 0; column < k; column += 1)
            staged[row * k + column] = (long)((accumulator >> column) & 1);
    }

    usz required = 8 * n * k;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < n * k; index += 1)
        store_i64_le(output, 8 * index, staged[index]);
    return (long)required;
}
