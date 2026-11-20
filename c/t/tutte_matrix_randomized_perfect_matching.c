#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_EDGES 28
#define MAX_INPUT 87
#define MAX_OUTPUT 80
#define FIELD_P INT64_C(65521)

static int64_t mod_norm(int64_t value)
{
    value %= FIELD_P;
    return value < 0 ? value + FIELD_P : value;
}

static int64_t mod_pow(int64_t value, uint64_t exponent)
{
    int64_t result = 1;
    int64_t factor = mod_norm(value);
    while (exponent != 0) {
        if ((exponent & UINT64_C(1)) != 0) result = (result * factor) % FIELD_P;
        factor = (factor * factor) % FIELD_P;
        exponent >>= 1;
    }
    return result;
}

static void store_i64(uint8_t *bytes, size_t word, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        bytes[word * 8 + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static int eliminate_pair(int64_t inverse[MAX_N * MAX_N], uint8_t rows[MAX_N],
                          uint8_t columns[MAX_N], int n, int pivot_row,
                          int pivot_column)
{
    int64_t old[MAX_N * MAX_N];
    for (int index = 0; index < MAX_N * MAX_N; ++index) old[index] = inverse[index];
    const int64_t pivot = old[pivot_row * MAX_N + pivot_column];
    if (pivot == 0) return 0;
    const int64_t inverse_pivot = mod_pow(pivot, (uint64_t)(FIELD_P - 2));
    for (int row = 0; row < n; ++row) {
        for (int column = 0; column < n; ++column) {
            if (rows[row] && row != pivot_row && columns[column] && column != pivot_column) {
                const int64_t correction = (old[row * MAX_N + pivot_column] *
                                            old[pivot_row * MAX_N + column]) % FIELD_P;
                inverse[row * MAX_N + column] = mod_norm(
                    old[row * MAX_N + column] - correction * inverse_pivot);
            } else {
                inverse[row * MAX_N + column] = 0;
            }
        }
    }
    rows[pivot_row] = 0;
    columns[pivot_column] = 0;
    return 1;
}

int64_t tutte_matrix_randomized_perfect_matching(const int64_t *input,
                                                 size_t length,
                                                 uint8_t *output,
                                                 size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t edge_count_value = input[1];
    if (n_value < 2 || n_value > MAX_N || (n_value & 1) != 0 ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES) return -1;
    const int n = (int)n_value;
    const int edge_count = (int)edge_count_value;
    if (edge_count > n * (n - 1) / 2 || length != (size_t)(2 + 3 * edge_count)) return -1;

    int64_t matrix[MAX_N * MAX_N] = {0};
    int64_t prior_u = -1, prior_v = -1;
    for (int edge = 0; edge < edge_count; ++edge) {
        const int64_t u_value = input[2 + 3 * edge];
        const int64_t v_value = input[3 + 3 * edge];
        const int64_t substitution = input[4 + 3 * edge];
        if (u_value < 0 || v_value <= u_value || v_value >= n ||
            (u_value < prior_u || (u_value == prior_u && v_value <= prior_v)) ||
            substitution < 1 || substitution >= FIELD_P) return -1;
        const int u = (int)u_value, v = (int)v_value;
        matrix[u * MAX_N + v] = substitution;
        matrix[v * MAX_N + u] = FIELD_P - substitution;
        prior_u = u_value;
        prior_v = v_value;
    }

    int64_t augmented[MAX_N * (2 * MAX_N)] = {0};
    for (int row = 0; row < n; ++row) {
        for (int column = 0; column < n; ++column)
            augmented[row * (2 * MAX_N) + column] = matrix[row * MAX_N + column];
        augmented[row * (2 * MAX_N) + n + row] = 1;
    }
    int singular = 0;
    for (int column = 0; column < n; ++column) {
        int pivot_row = column;
        while (pivot_row < n && augmented[pivot_row * (2 * MAX_N) + column] == 0) ++pivot_row;
        if (pivot_row == n) { singular = 1; break; }
        if (pivot_row != column) {
            for (int j = 0; j < 2 * n; ++j) {
                const int64_t temporary = augmented[column * (2 * MAX_N) + j];
                augmented[column * (2 * MAX_N) + j] = augmented[pivot_row * (2 * MAX_N) + j];
                augmented[pivot_row * (2 * MAX_N) + j] = temporary;
            }
        }
        const int64_t inverse_pivot = mod_pow(
            augmented[column * (2 * MAX_N) + column], (uint64_t)(FIELD_P - 2));
        for (int j = 0; j < 2 * n; ++j)
            augmented[column * (2 * MAX_N) + j] =
                (augmented[column * (2 * MAX_N) + j] * inverse_pivot) % FIELD_P;
        for (int row = 0; row < n; ++row) {
            if (row == column) continue;
            const int64_t factor = augmented[row * (2 * MAX_N) + column];
            if (factor == 0) continue;
            for (int j = 0; j < 2 * n; ++j) {
                augmented[row * (2 * MAX_N) + j] = mod_norm(
                    augmented[row * (2 * MAX_N) + j] -
                    factor * augmented[column * (2 * MAX_N) + j]);
            }
        }
    }

    int64_t result_words[2 + MAX_N] = {0};
    size_t result_count = 2;
    if (!singular) {
        int64_t inverse[MAX_N * MAX_N] = {0};
        for (int row = 0; row < n; ++row)
            for (int column = 0; column < n; ++column)
                inverse[row * MAX_N + column] = augmented[row * (2 * MAX_N) + n + column];
        uint8_t rows[MAX_N] = {0}, columns[MAX_N] = {0};
        for (int i = 0; i < n; ++i) rows[i] = columns[i] = 1;
        int failed = 0;
        for (int vertex = 0; vertex < n; ++vertex) {
            if (!columns[vertex]) continue;
            int partner = -1;
            for (int candidate = 0; candidate < n; ++candidate) {
                if (rows[candidate] && candidate != vertex &&
                    matrix[vertex * MAX_N + candidate] != 0 &&
                    inverse[candidate * MAX_N + vertex] != 0) {
                    partner = candidate;
                    break;
                }
            }
            if (partner < 0 || result_count + 2 > 2 + MAX_N) { failed = 1; break; }
            result_words[result_count++] = vertex;
            result_words[result_count++] = partner;
            if (!eliminate_pair(inverse, rows, columns, n, partner, vertex) ||
                !eliminate_pair(inverse, rows, columns, n, vertex, partner)) {
                failed = 1;
                break;
            }
        }
        if (failed) result_count = 2;
        else {
            result_words[0] = 1;
            result_words[1] = n / 2;
        }
    }
    const size_t output_bytes = result_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT] = {0};
    for (size_t word = 0; word < result_count; ++word) store_i64(staged, word, result_words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
