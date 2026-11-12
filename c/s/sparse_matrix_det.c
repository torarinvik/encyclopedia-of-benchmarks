#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MOD INT64_C(998244353)
#define MAX_N 8
#define MAX_K 64
#define MAX_VALID_INPUT_VALUES (2 + 3 * MAX_K)
#define MAX_PARSEABLE_INPUT_VALUES (MAX_VALID_INPUT_VALUES + 1)
#define MAX_ATTEMPTS 4

static int64_t add_mod(int64_t a, int64_t b) {
    a += b;
    return a >= MOD ? a - MOD : a;
}

static int64_t sub_mod(int64_t a, int64_t b) {
    a -= b;
    return a < 0 ? a + MOD : a;
}

static int64_t mul_mod(int64_t a, int64_t b) {
    return (a * b) % MOD;
}

static int64_t pow_mod(int64_t value, int64_t exponent) {
    int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = mul_mod(result, value);
        value = mul_mod(value, value);
        exponent >>= 1;
    }
    return result;
}

static int64_t next_residue(int64_t *state) {
    *state = (*state * INT64_C(48271) + 1) % MOD;
    return *state;
}

static int berlekamp_massey(const int64_t *sequence, int length,
                            int64_t *connection) {
    int64_t previous[MAX_N + 1] = {0};
    int64_t temporary[MAX_N + 1] = {0};
    for (int i = 0; i <= MAX_N; ++i) connection[i] = 0;
    connection[0] = 1;
    previous[0] = 1;
    int degree = 0;
    int shift = 1;
    int previous_degree = 0;
    int64_t last_discrepancy = 1;

    for (int index = 0; index < length; ++index) {
        int64_t discrepancy = sequence[index];
        for (int i = 1; i <= degree; ++i)
            discrepancy = add_mod(discrepancy,
                mul_mod(connection[i], sequence[index - i]));
        if (discrepancy == 0) {
            ++shift;
            continue;
        }

        for (int i = 0; i <= MAX_N; ++i) temporary[i] = connection[i];
        const int64_t scale = mul_mod(discrepancy,
                                      pow_mod(last_discrepancy, MOD - 2));
        for (int i = 0; i <= previous_degree; ++i) {
            const int target = i + shift;
            if (target <= MAX_N)
                connection[target] = sub_mod(connection[target],
                                               mul_mod(scale, previous[i]));
        }

        if (2 * degree <= index) {
            const int old_degree = degree;
            degree = index + 1 - degree;
            for (int i = 0; i <= MAX_N; ++i) previous[i] = temporary[i];
            previous_degree = old_degree;
            last_discrepancy = discrepancy;
            shift = 1;
        } else {
            ++shift;
        }
    }
    return degree;
}

static int64_t dense_determinant(const int64_t *entry, const int *row,
                                const int *column, int n, int k) {
    int64_t matrix[MAX_N][MAX_N] = {{0}};
    for (int e = 0; e < k; ++e) matrix[row[e]][column[e]] = entry[e];

    int64_t determinant = 1;
    for (int pivot_column = 0; pivot_column < n; ++pivot_column) {
        int pivot = pivot_column;
        while (pivot < n && matrix[pivot][pivot_column] == 0) ++pivot;
        if (pivot == n) return 0;
        if (pivot != pivot_column) {
            for (int j = 0; j < n; ++j) {
                const int64_t temporary = matrix[pivot_column][j];
                matrix[pivot_column][j] = matrix[pivot][j];
                matrix[pivot][j] = temporary;
            }
            determinant = determinant == 0 ? 0 : MOD - determinant;
        }
        const int64_t pivot_value = matrix[pivot_column][pivot_column];
        determinant = mul_mod(determinant, pivot_value);
        const int64_t inverse = pow_mod(pivot_value, MOD - 2);
        for (int i = pivot_column + 1; i < n; ++i) {
            if (matrix[i][pivot_column] == 0) continue;
            const int64_t factor = mul_mod(matrix[i][pivot_column], inverse);
            for (int j = pivot_column + 1; j < n; ++j)
                matrix[i][j] = sub_mod(matrix[i][j],
                                       mul_mod(factor, matrix[pivot_column][j]));
            matrix[i][pivot_column] = 0;
        }
    }
    return determinant;
}

static int64_t sparse_wiedemann(const int *row, const int *column,
                                const int64_t *entry, int n, int k,
                                int64_t seed, bool *success) {
    int64_t diagonal[MAX_N], left[MAX_N], vector[MAX_N];
    int64_t sequence[2 * MAX_N] = {0};
    int64_t next[MAX_N], weighted[MAX_N];
    int64_t diagonal_product = 1;
    for (int i = 0; i < n; ++i) {
        diagonal[i] = next_residue(&seed);
        if (diagonal[i] == 0) diagonal[i] = 1;
        left[i] = next_residue(&seed);
        vector[i] = next_residue(&seed);
        diagonal_product = mul_mod(diagonal_product, diagonal[i]);
    }

    for (int step = 0; step < 2 * n; ++step) {
        int64_t dot = 0;
        for (int i = 0; i < n; ++i) dot = add_mod(dot, mul_mod(left[i], vector[i]));
        sequence[step] = dot;
        for (int i = 0; i < n; ++i) weighted[i] = mul_mod(diagonal[i], vector[i]);
        for (int i = 0; i < n; ++i) next[i] = 0;
        for (int e = 0; e < k; ++e)
            next[row[e]] = add_mod(next[row[e]],
                                   mul_mod(entry[e], weighted[column[e]]));
        for (int i = 0; i < n; ++i) vector[i] = next[i];
    }

    int64_t connection[MAX_N + 1];
    const int degree = berlekamp_massey(sequence, 2 * n, connection);
    if (degree != n) {
        *success = false;
        return 0;
    }
    int64_t constant = connection[n];
    if ((n & 1) != 0 && constant != 0) constant = MOD - constant;
    *success = true;
    return mul_mod(constant, pow_mod(diagonal_product, MOD - 2));
}

static void store_i64_le(uint8_t *output, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t sparse_matrix_det(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], k_value = input[1];
    if (n_value < 1 || n_value > MAX_N || k_value < 1 || k_value > MAX_K) return -1;
    const int n = (int)n_value, k = (int)k_value;
    if (length != (size_t)(2 + 3 * k)) return -1;

    bool seen[MAX_N][MAX_N] = {{false}};
    int row[MAX_K], column[MAX_K];
    int64_t entry[MAX_K];
    for (int e = 0; e < k; ++e) {
        const int64_t r = input[2 + 3 * e];
        const int64_t c = input[3 + 3 * e];
        const int64_t value = input[4 + 3 * e];
        if (r < 0 || r >= n || c < 0 || c >= n
            || value < 1 || value >= MOD || seen[r][c]) return -1;
        row[e] = (int)r;
        column[e] = (int)c;
        entry[e] = value;
        seen[r][c] = true;
    }

    int64_t determinant = 0;
    bool found = false;
    for (int attempt = 0; attempt < MAX_ATTEMPTS; ++attempt) {
        int64_t seed = INT64_C(104729) + (int64_t)attempt * INT64_C(1000003);
        if (seed >= MOD) seed %= MOD;
        determinant = sparse_wiedemann(row, column, entry, n, k, seed, &found);
        if (found) break;
    }
    if (!found) determinant = dense_determinant(entry, row, column, n, k);

    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, determinant);
    return 8;
}
