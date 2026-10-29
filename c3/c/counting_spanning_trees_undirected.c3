module counting_spanning_trees_undirected;

const long MODULUS = 1000000007;

fn long modular_power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn long counting_spanning_trees_undirected(long* input, usz length,
        uint8* output, usz output_capacity) @export("counting_spanning_trees_undirected") {
    if (input == null || length < 2 || length > 44) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > 7 || m_value < 0 || m_value > 21) return -1;
    usz n = (usz)n_value;
    usz edge_count = (usz)m_value;
    if (length != 2 + 2 * edge_count) return -1;

    bool[7][7] adjacent = zeroed;
    for (usz edge = 0; edge < edge_count; edge++) {
        long u_value = input[2 + 2 * edge];
        long v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    if (output == null || output_capacity < 8) return -2;

    usz dimension = n - 1;
    long[7][7] matrix = zeroed;
    for (usz row = 0; row < dimension; row++) {
        long degree = 0;
        for (usz column = 0; column < n; column++) {
            if (!adjacent[row][column]) continue;
            degree++;
            if (column < dimension) matrix[row][column] = MODULUS - 1;
        }
        matrix[row][row] = degree;
    }

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
