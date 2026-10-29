module counting_spanning_trees_directed;

const long MODULUS = 998244353;

fn long modular_power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn long counting_spanning_trees_directed(long* input, usz length,
        uint8* output, usz output_capacity) @export("counting_spanning_trees_directed") {
    if (input == null || length < 3 || length > 27) return -1;
    long n_value = input[0];
    long m_value = input[1];
    long root_value = input[2];
    if (n_value < 1 || n_value > 6 || m_value < 0 || m_value > 12 ||
        root_value < 0 || root_value >= n_value) return -1;
    usz n = (usz)n_value;
    usz edge_count = (usz)m_value;
    usz root = (usz)root_value;
    if (length != 3 + 2 * edge_count) return -1;

    usz dimension = n - 1;
    long[6][6] matrix = zeroed;
    for (usz edge = 0; edge < edge_count; edge++) {
        long u_value = input[3 + 2 * edge];
        long v_value = input[4 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value) return -1;
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        if (u == v || v == root) continue;
        usz row = v < root ? v : v - 1;
        matrix[row][row] = (matrix[row][row] + 1) % MODULUS;
        if (u != root) {
            usz column = u < root ? u : u - 1;
            matrix[row][column] = (matrix[row][column] + MODULUS - 1) % MODULUS;
        }
    }
    if (output == null || output_capacity < 8) return -2;

    long determinant = 1;
    for (usz column = 0; column < dimension; column++) {
        usz pivot = column;
        while (pivot < dimension && matrix[pivot][column] == 0) pivot++;
        if (pivot == dimension) { determinant = 0; break; }
        if (pivot != column) {
            for (usz j = 0; j < dimension; j++) {
                long temporary = matrix[column][j];
                matrix[column][j] = matrix[pivot][j];
                matrix[pivot][j] = temporary;
            }
            determinant = (MODULUS - determinant) % MODULUS;
        }
        long pivot_value = matrix[column][column];
        determinant = (determinant * pivot_value) % MODULUS;
        long inverse = modular_power(pivot_value, MODULUS - 2);
        for (usz row = column + 1; row < dimension; row++) {
            long factor = (matrix[row][column] * inverse) % MODULUS;
            for (usz j = column; j < dimension; j++)
                matrix[row][j] = (matrix[row][j] - factor * matrix[column][j] % MODULUS + MODULUS) % MODULUS;
        }
    }
    ulong answer = (ulong)determinant;
    for (usz byte = 0; byte < 8; byte++) output[byte] = (uint8)(answer >> (8 * byte));
    return 8;
}
