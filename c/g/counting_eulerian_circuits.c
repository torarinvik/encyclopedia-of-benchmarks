#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 7, MAX_EDGES = 9, MAX_INPUT_LENGTH = 20 };
static const int64_t MODULUS = INT64_C(998244353);

static int64_t modular_power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

int64_t counting_eulerian_circuits(const int64_t *values, size_t length,
                                    uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = values[0];
    const int64_t m_value = values[1];
    if (n_value < 1 || n_value > MAX_VERTICES || m_value < 1 || m_value > MAX_EDGES) return -1;
    const size_t n = (size_t)n_value;
    const size_t edge_count = (size_t)m_value;
    if (length != 2 + 2 * edge_count) return -1;

    size_t indegree[MAX_VERTICES] = {0};
    size_t outdegree[MAX_VERTICES] = {0};
    size_t start = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t u_value = values[2 + 2 * edge];
        const int64_t v_value = values[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value) return -1;
        const size_t u = (size_t)u_value;
        const size_t v = (size_t)v_value;
        if (edge == 0) start = u;
        ++outdegree[u];
        ++indegree[v];
    }

    int balanced = 1;
    for (size_t vertex = 0; vertex < n; ++vertex)
        if (indegree[vertex] != outdegree[vertex]) balanced = 0;

    int64_t answer = 0;
    if (balanced) {
        size_t active_id[MAX_VERTICES];
        size_t active_count = 0;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            active_id[vertex] = SIZE_MAX;
            if (indegree[vertex] != 0) active_id[vertex] = active_count++;
        }
        const size_t root_id = active_id[start];
        const size_t dimension = active_count - 1;
        int64_t matrix[MAX_VERTICES][MAX_VERTICES] = {{0}};
        for (size_t edge = 0; edge < edge_count; ++edge) {
            const size_t u = (size_t)values[2 + 2 * edge];
            const size_t v = (size_t)values[3 + 2 * edge];
            if (u == start) continue;
            size_t row = active_id[u];
            if (row > root_id) --row;
            matrix[row][row] = (matrix[row][row] + 1) % MODULUS;
            if (v != start) {
                size_t column = active_id[v];
                if (column > root_id) --column;
                matrix[row][column] = (matrix[row][column] + MODULUS - 1) % MODULUS;
            }
        }

        int64_t determinant = 1;
        for (size_t column = 0; column < dimension; ++column) {
            size_t pivot = column;
            while (pivot < dimension && matrix[pivot][column] == 0) ++pivot;
            if (pivot == dimension) {
                determinant = 0;
                break;
            }
            if (pivot != column) {
                for (size_t j = 0; j < dimension; ++j) {
                    const int64_t temporary = matrix[column][j];
                    matrix[column][j] = matrix[pivot][j];
                    matrix[pivot][j] = temporary;
                }
                determinant = (MODULUS - determinant) % MODULUS;
            }
            const int64_t pivot_value = matrix[column][column];
            determinant = (determinant * pivot_value) % MODULUS;
            const int64_t inverse = modular_power(pivot_value, MODULUS - 2);
            for (size_t row = column + 1; row < dimension; ++row) {
                const int64_t factor = (matrix[row][column] * inverse) % MODULUS;
                for (size_t j = column; j < dimension; ++j)
                    matrix[row][j] = (matrix[row][j] - factor * matrix[column][j] % MODULUS + MODULUS) % MODULUS;
            }
        }
        answer = determinant;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (outdegree[vertex] == 0) continue;
            for (size_t factor = 2; factor < outdegree[vertex]; ++factor)
                answer = (answer * (int64_t)factor) % MODULUS;
        }
    }

    if (output == NULL || output_capacity < 8) return -2;
    const uint64_t encoded = (uint64_t)answer;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(encoded >> (8 * byte));
    return 8;
}
