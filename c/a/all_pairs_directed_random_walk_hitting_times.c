#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT_LENGTH = 115 };
static const int64_t MOD = INT64_C(1000000007);

static int64_t mod_norm(int64_t value) {
    value %= MOD;
    return value < 0 ? value + MOD : value;
}

static int64_t mod_pow(int64_t base, int64_t exponent) {
    int64_t result = 1;
    base = mod_norm(base);
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % MOD;
        base = (base * base) % MOD;
        exponent >>= 1;
    }
    return result;
}

static int connected(const uint8_t graph[MAX_N][MAX_N], size_t n, int reverse) {
    uint8_t seen[MAX_N] = {0};
    size_t queue[MAX_N];
    size_t head = 0, tail = 0;
    seen[0] = 1;
    queue[tail++] = 0;
    while (head < tail) {
        const size_t from = queue[head++];
        for (size_t to = 0; to < n; ++to) {
            const int has_edge = reverse ? graph[to][from] : graph[from][to];
            if (has_edge && !seen[to]) {
                seen[to] = 1;
                queue[tail++] = to;
            }
        }
    }
    return tail == n;
}

static int solve(int64_t matrix[MAX_N][2 * MAX_N + 1], size_t size,
                 size_t rhs_count) {
    const size_t width = size + rhs_count;
    for (size_t column = 0; column < size; ++column) {
        size_t pivot = column;
        while (pivot < size && mod_norm(matrix[pivot][column]) == 0) ++pivot;
        if (pivot == size) return 0;
        if (pivot != column) {
            for (size_t j = 0; j < width; ++j) {
                const int64_t temp = matrix[column][j];
                matrix[column][j] = matrix[pivot][j];
                matrix[pivot][j] = temp;
            }
        }
        const int64_t scale = mod_pow(matrix[column][column], MOD - 2);
        for (size_t j = 0; j < width; ++j)
            matrix[column][j] = (matrix[column][j] * scale) % MOD;
        for (size_t row = 0; row < size; ++row) {
            if (row == column) continue;
            const int64_t factor = mod_norm(matrix[row][column]);
            if (factor == 0) continue;
            for (size_t j = 0; j < width; ++j)
                matrix[row][j] = mod_norm(matrix[row][j]
                    - factor * matrix[column][j] % MOD);
        }
    }
    return 1;
}

static void store_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t all_pairs_directed_random_walk_hitting_times(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 3 || n_value > MAX_N) return -1;
    if (m_value < 0 || m_value > n_value * (n_value - 1)) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + 2 * m) return -1;

    uint8_t graph[MAX_N][MAX_N] = {{0}};
    size_t degree[MAX_N] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u_value = input[2 + 2 * edge];
        const int64_t v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value
                || u_value == v_value) return -1;
        const size_t u = (size_t)u_value, v = (size_t)v_value;
        if (graph[u][v]) return -1;
        graph[u][v] = 1;
        ++degree[u];
    }
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (degree[vertex] == 0) return -1;
    if (!connected(graph, n, 0) || !connected(graph, n, 1)) return -1;

    const size_t output_bytes = 8 * n * n;
    if (output == NULL || capacity < output_bytes) return -2;

    int64_t stationary[MAX_N][2 * MAX_N + 1] = {{0}};
    for (size_t destination = 0; destination + 1 < n; ++destination) {
        for (size_t source = 0; source < n; ++source) {
            const int64_t transition = graph[source][destination]
                ? mod_pow((int64_t)degree[source], MOD - 2) : 0;
            stationary[destination][source] = mod_norm(transition
                - (source == destination ? 1 : 0));
        }
    }
    for (size_t source = 0; source < n; ++source)
        stationary[n - 1][source] = 1;
    stationary[n - 1][n] = 1;
    if (!solve(stationary, n, 1)) return -1;

    int64_t reciprocal[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        const int64_t pi = mod_norm(stationary[vertex][n]);
        if (pi == 0) return -1;
        reciprocal[vertex] = mod_pow(pi, MOD - 2);
    }

    int64_t reduced[MAX_N][2 * MAX_N + 1] = {{0}};
    for (size_t row = 0; row + 1 < n; ++row) {
        for (size_t column = 0; column + 1 < n; ++column) {
            const int64_t transition = graph[row][column]
                ? mod_pow((int64_t)degree[row], MOD - 2) : 0;
            reduced[row][column] = mod_norm((row == column ? 1 : 0) - transition);
        }
        for (size_t target = 0; target < n; ++target)
            reduced[row][n - 1 + target] = mod_norm(1
                - (row == target ? reciprocal[target] : 0));
    }
    if (!solve(reduced, n - 1, n)) return -1;

    int64_t y[MAX_N][MAX_N] = {{0}};
    int64_t answer[MAX_N][MAX_N] = {{0}};
    for (size_t row = 0; row + 1 < n; ++row)
        for (size_t target = 0; target < n; ++target)
            y[row][target] = mod_norm(reduced[row][n - 1 + target]);
    for (size_t source = 0; source < n; ++source)
        for (size_t target = 0; target < n; ++target)
            answer[source][target] = mod_norm(y[source][target] - y[target][target]);

    for (size_t source = 0; source < n; ++source)
        for (size_t target = 0; target < n; ++target)
            store_i64_le(output + 8 * (source * n + target), answer[source][target]);
    return (int64_t)output_bytes;
}
