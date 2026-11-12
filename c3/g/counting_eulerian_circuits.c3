module counting_eulerian_circuits;

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

fn long counting_eulerian_circuits(long* input, usz length,
        uint8* output, usz output_capacity) @export("counting_eulerian_circuits") {
    if (input == null || length < 2 || length > 20) return -1;
    long n_value = input[0];
    long m_value = input[1];
    if (n_value < 1 || n_value > 7 || m_value < 1 || m_value > 9) return -1;
    usz n = (usz)n_value;
    usz edge_count = (usz)m_value;
    if (length != 2 + 2 * edge_count) return -1;

    usz[7] indegree = zeroed;
    usz[7] outdegree = zeroed;
    usz start = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long u_value = input[2 + 2 * edge];
        long v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value) return -1;
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        if (edge == 0) start = u;
        outdegree[u]++;
        indegree[v]++;
    }

    bool balanced = true;
    for (usz vertex = 0; vertex < n; vertex++)
        if (indegree[vertex] != outdegree[vertex]) balanced = false;

    long answer = 0;
    if (balanced) {
        usz[7] active_id;
        usz active_count = 0;
        for (usz vertex = 0; vertex < n; vertex++) {
            active_id[vertex] = 7;
            if (indegree[vertex] != 0) active_id[vertex] = active_count++;
        }
        usz root_id = active_id[start];
        usz dimension = active_count - 1;
        long[7][7] matrix = zeroed;
        for (usz edge = 0; edge < edge_count; edge++) {
            usz u = (usz)input[2 + 2 * edge];
            usz v = (usz)input[3 + 2 * edge];
            if (u == start) continue;
            usz row = active_id[u];
            if (row > root_id) row--;
            matrix[row][row] = (matrix[row][row] + 1) % MODULUS;
            if (v != start) {
                usz column = active_id[v];
                if (column > root_id) column--;
                matrix[row][column] = (matrix[row][column] + MODULUS - 1) % MODULUS;
            }
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
        answer = determinant;
        for (usz vertex = 0; vertex < n; vertex++)
            for (usz factor = 2; factor < outdegree[vertex]; factor++)
                answer = (answer * (long)factor) % MODULUS;
    }

    if (output == null || output_capacity < 8) return -2;
    ulong encoded = (ulong)answer;
    for (usz byte = 0; byte < 8; byte++) output[byte] = (uint8)(encoded >> (8 * byte));
    return 8;
}
