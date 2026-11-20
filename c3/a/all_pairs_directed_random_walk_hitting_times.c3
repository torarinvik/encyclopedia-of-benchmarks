module all_pairs_directed_random_walk_hitting_times;

const usz MAX_N = 8;
const usz MATRIX_WIDTH = 17;
const usz MAX_INPUT_LENGTH = 115;
const long MODULUS = 1000000007;

fn long norm(long value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

fn long power(long base, long exponent) {
    long result = 1;
    base = norm(base);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn bool reaches_all(long* graph, usz n, bool reverse) {
    bool[MAX_N] seen;
    usz[MAX_N] queue;
    usz head = 0, tail = 1;
    for (usz i = 0; i < MAX_N; i++) seen[i] = false;
    seen[0] = true;
    queue[0] = 0;
    while (head < tail) {
        usz from = queue[head++];
        for (usz to = 0; to < n; to++) {
            bool edge = reverse ? graph[to * MAX_N + from] != 0
                                : graph[from * MAX_N + to] != 0;
            if (edge && !seen[to]) { seen[to] = true; queue[tail++] = to; }
        }
    }
    return tail == n;
}

fn bool eliminate(long* matrix, usz size, usz rhs_count) {
    usz width = size + rhs_count;
    for (usz column = 0; column < size; column++) {
        usz pivot = column;
        while (pivot < size && norm(matrix[pivot * MATRIX_WIDTH + column]) == 0) pivot++;
        if (pivot == size) return false;
        if (pivot != column) {
            for (usz j = 0; j < width; j++) {
                long temp = matrix[column * MATRIX_WIDTH + j];
                matrix[column * MATRIX_WIDTH + j] = matrix[pivot * MATRIX_WIDTH + j];
                matrix[pivot * MATRIX_WIDTH + j] = temp;
            }
        }
        long inverse = power(matrix[column * MATRIX_WIDTH + column], MODULUS - 2);
        for (usz j = 0; j < width; j++)
            matrix[column * MATRIX_WIDTH + j] = matrix[column * MATRIX_WIDTH + j] * inverse % MODULUS;
        for (usz row = 0; row < size; row++) {
            if (row == column) continue;
            long factor = norm(matrix[row * MATRIX_WIDTH + column]);
            if (factor == 0) continue;
            for (usz j = 0; j < width; j++)
                matrix[row * MATRIX_WIDTH + j] = norm(matrix[row * MATRIX_WIDTH + j]
                    - factor * matrix[column * MATRIX_WIDTH + j] % MODULUS);
        }
    }
    return true;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long all_pairs_directed_random_walk_hitting_times(long* input, usz length,
        char* output, usz capacity) @export("all_pairs_directed_random_walk_hitting_times") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 3 || n_value > 8) return -1;
    if (m_value < 0 || m_value > n_value * (n_value - 1)) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 2 * m) return -1;
    long[MAX_N * MAX_N] graph;
    usz[MAX_N] degree;
    for (usz i = 0; i < MAX_N * MAX_N; i++) graph[i] = 0;
    for (usz i = 0; i < MAX_N; i++) degree[i] = 0;
    for (usz e = 0; e < m; e++) {
        long u_value = input[2 + 2 * e], v_value = input[3 + 2 * e];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        if (graph[u * MAX_N + v] != 0) return -1;
        graph[u * MAX_N + v] = 1;
        degree[u]++;
    }
    for (usz i = 0; i < n; i++) if (degree[i] == 0) return -1;
    if (!reaches_all(&graph[0], n, false) || !reaches_all(&graph[0], n, true)) return -1;
    usz output_bytes = 8 * n * n;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_N * MATRIX_WIDTH] stationary;
    long[MAX_N * MATRIX_WIDTH] reduced;
    for (usz i = 0; i < MAX_N * MATRIX_WIDTH; i++) { stationary[i] = 0; reduced[i] = 0; }
    for (usz destination = 0; destination + 1 < n; destination++) {
        for (usz source = 0; source < n; source++) {
            long transition = graph[source * MAX_N + destination] != 0
                ? power((long)degree[source], MODULUS - 2) : 0;
            stationary[destination * MATRIX_WIDTH + source] = norm(transition - (source == destination ? 1 : 0));
        }
    }
    for (usz source = 0; source < n; source++) stationary[(n - 1) * MATRIX_WIDTH + source] = 1;
    stationary[(n - 1) * MATRIX_WIDTH + n] = 1;
    if (!eliminate(&stationary[0], n, 1)) return -1;
    long[MAX_N] reciprocal;
    for (usz vertex = 0; vertex < n; vertex++) {
        long pi = norm(stationary[vertex * MATRIX_WIDTH + n]);
        if (pi == 0) return -1;
        reciprocal[vertex] = power(pi, MODULUS - 2);
    }
    for (usz row = 0; row + 1 < n; row++) {
        for (usz column = 0; column + 1 < n; column++) {
            long transition = graph[row * MAX_N + column] != 0
                ? power((long)degree[row], MODULUS - 2) : 0;
            reduced[row * MATRIX_WIDTH + column] = norm((row == column ? 1 : 0) - transition);
        }
        for (usz target = 0; target < n; target++)
            reduced[row * MATRIX_WIDTH + n - 1 + target] = norm(1 - (row == target ? reciprocal[target] : 0));
    }
    if (!eliminate(&reduced[0], n - 1, n)) return -1;
    long[MAX_N * MAX_N] y;
    for (usz i = 0; i < MAX_N * MAX_N; i++) y[i] = 0;
    for (usz row = 0; row + 1 < n; row++)
        for (usz target = 0; target < n; target++)
            y[row * MAX_N + target] = norm(reduced[row * MATRIX_WIDTH + n - 1 + target]);
    for (usz source = 0; source < n; source++) {
        for (usz target = 0; target < n; target++) {
            long answer = norm(y[source * MAX_N + target] - y[target * MAX_N + target]);
            store_i64_le(output, 8 * (source * n + target), answer);
        }
    }
    return (long)output_bytes;
}
