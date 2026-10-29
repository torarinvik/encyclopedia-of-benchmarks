#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 7, MAX_EDGES = 21, MAX_INPUT_LENGTH = 44 };
static const int64_t MODULUS = INT64_C(1000000007);

static int64_t modular_power(int64_t base, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = (result * base) % MODULUS;
        base = (base * base) % MODULUS;
        exponent >>= 1;
    }
    return result;
}

int64_t counting_spanning_trees_undirected(const int64_t *values, size_t length,
                                            uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n_value = values[0];
    const int64_t m_value = values[1];
    if (n_value < 1 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES) return -1;
    const size_t n = (size_t)n_value;
    const size_t edge_count = (size_t)m_value;
    if (length != 2 + 2 * edge_count) return -1;

    uint8_t adjacent[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t u_value = values[2 + 2 * edge];
        const int64_t v_value = values[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            u_value == v_value) return -1;
        const size_t u = (size_t)u_value;
        const size_t v = (size_t)v_value;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = 1;
        adjacent[v][u] = 1;
    }
    if (output == NULL || output_capacity < 8) return -2;

    const size_t dimension = n - 1;
    int64_t matrix[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (size_t row = 0; row < dimension; ++row) {
        int64_t degree = 0;
        for (size_t column = 0; column < n; ++column) {
            if (!adjacent[row][column]) continue;
            ++degree;
            if (column < dimension) matrix[row][column] = MODULUS - 1;
        }
        matrix[row][row] = degree;
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
            for (size_t j = column; j < dimension; ++j) {
                matrix[row][j] = (matrix[row][j] - factor * matrix[column][j] % MODULUS + MODULUS) % MODULUS;
            }
        }
    }

    const uint64_t answer = (uint64_t)determinant;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(answer >> (8 * byte));
    return 8;
}
