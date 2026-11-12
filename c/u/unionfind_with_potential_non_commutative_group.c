#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 64
#define MAX_INPUT_VALUES (2 + 7 * MAX_Q)
#define MODULUS INT64_C(998244353)

typedef struct { int64_t value[4]; } Matrix;

static int64_t normalize(int64_t value) {
    value %= MODULUS;
    return value < 0 ? value + MODULUS : value;
}

static Matrix matrix_multiply(Matrix left, Matrix right) {
    Matrix result = {{0, 0, 0, 0}};
    for (size_t row = 0; row < 2; ++row)
        for (size_t column = 0; column < 2; ++column)
            for (size_t inner = 0; inner < 2; ++inner)
                result.value[2 * row + column] = normalize(
                    result.value[2 * row + column] +
                    left.value[2 * row + inner] * right.value[2 * inner + column]);
    return result;
}

static Matrix matrix_inverse(Matrix matrix) {
    Matrix inverse = {{matrix.value[3], normalize(-matrix.value[1]),
                       normalize(-matrix.value[2]), matrix.value[0]}};
    return inverse;
}

static int matrix_equal(Matrix left, Matrix right) {
    for (size_t i = 0; i < 4; ++i)
        if (left.value[i] != right.value[i]) return 0;
    return 1;
}

static size_t find_root(size_t *parent, Matrix *difference, size_t item) {
    if (parent[item] != item) {
        const size_t old_parent = parent[item];
        const size_t root = find_root(parent, difference, old_parent);
        difference[item] = matrix_multiply(difference[old_parent], difference[item]);
        parent[item] = root;
    }
    return parent[item];
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t unionfind_with_potential_non_commutative_group(const int64_t *input,
    size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 9 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + 7 * q) return -1;

    for (size_t operation = 0; operation < q; ++operation) {
        const size_t position = 2 + 7 * operation;
        const int64_t kind = input[position], u = input[position + 1];
        const int64_t v = input[position + 2];
        if (u < 0 || u >= n_value || v < 0 || v >= n_value) return -1;
        if (kind == 0) {
            const int64_t a = input[position + 3], b = input[position + 4];
            const int64_t c = input[position + 5], d = input[position + 6];
            if (a < 0 || a >= MODULUS || b < 0 || b >= MODULUS ||
                c < 0 || c >= MODULUS || d < 0 || d >= MODULUS ||
                normalize(a * d - b * c) != 1) return -1;
        } else if (kind == 1) {
            for (size_t cell = 0; cell < 4; ++cell)
                if (input[position + 3 + cell] != 0) return -1;
        } else {
            return -1;
        }
    }
    const size_t required = 32 * q;
    if (output == NULL || capacity < required) return -2;

    size_t parent[MAX_N], set_size[MAX_N];
    Matrix difference[MAX_N] = {0};
    for (size_t item = 0; item < n; ++item) {
        parent[item] = item;
        set_size[item] = 1;
        difference[item].value[0] = difference[item].value[3] = 1;
    }
    for (size_t operation = 0; operation < q; ++operation) {
        const size_t position = 2 + 7 * operation;
        const int64_t kind = input[position];
        const size_t u = (size_t)input[position + 1], v = (size_t)input[position + 2];
        int64_t row[4] = {0, 0, 0, 0};
        const size_t root_u = find_root(parent, difference, u);
        const size_t root_v = find_root(parent, difference, v);
        if (kind == 1) {
            if (root_u == root_v) {
                const Matrix relative = matrix_multiply(matrix_inverse(difference[v]), difference[u]);
                for (size_t cell = 0; cell < 4; ++cell) row[cell] = relative.value[cell];
            } else {
                for (size_t cell = 0; cell < 4; ++cell) row[cell] = -1;
            }
        } else {
            const Matrix relation = {{input[position + 3], input[position + 4],
                                      input[position + 5], input[position + 6]}};
            if (root_u == root_v) {
                const Matrix known = matrix_multiply(matrix_inverse(difference[v]), difference[u]);
                row[0] = matrix_equal(known, relation);
            } else if (set_size[root_u] < set_size[root_v]) {
                const Matrix first = matrix_multiply(difference[v], relation);
                difference[root_u] = matrix_multiply(first, matrix_inverse(difference[u]));
                parent[root_u] = root_v;
                set_size[root_v] += set_size[root_u];
                row[0] = 1;
            } else {
                const Matrix first = matrix_multiply(difference[u], matrix_inverse(relation));
                difference[root_v] = matrix_multiply(first, matrix_inverse(difference[v]));
                parent[root_v] = root_u;
                set_size[root_u] += set_size[root_v];
                row[0] = 1;
            }
        }
        for (size_t cell = 0; cell < 4; ++cell) store_i64_le(output, 32 * operation + 8 * cell, row[cell]);
    }
    return (int64_t)required;
}
