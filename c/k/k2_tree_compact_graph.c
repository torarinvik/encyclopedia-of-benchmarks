/* Clean-room bounded packed k²-tree graph query profile. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 128
#define MAX_INPUT 419
#define T_MAX_BITS 340
#define L_MAX_BITS 1024
#define T_BYTES 43
#define L_BYTES 128
#define NODE_CAP 256

static uint8_t bit_get(const uint8_t *bits, size_t index) {
    return (uint8_t)((bits[index >> 3] >> (index & 7)) & 1u);
}

static void bit_set(uint8_t *bits, size_t index) {
    bits[index >> 3] |= (uint8_t)(1u << (index & 7));
}

static int block_nonempty(const int64_t *rows, size_t n, size_t row_start,
                          size_t col_start, size_t side) {
    const uint64_t column_mask = ((UINT64_C(1) << side) - 1) << col_start;
    for (size_t row = row_start; row < row_start + side; ++row)
        if (row < n && ((uint64_t)rows[row] & column_mask) != 0) return 1;
    return 0;
}

static void build_tree(const int64_t *rows, size_t n,
                       uint8_t *t_bits, uint8_t *l_bits, uint16_t *rank_prefix,
                       uint8_t *current_rows, uint8_t *current_cols,
                       uint8_t *next_rows, uint8_t *next_cols,
                       size_t *t_length, size_t *l_length, size_t *height_out) {
    size_t side = 2, height = 1;
    while (side < n) { side <<= 1; ++height; }
    size_t current_count = 1, current_side = side;
    size_t t_used = 0, l_used = 0;
    current_rows[0] = 0;
    current_cols[0] = 0;
    for (size_t level = 1; level <= height; ++level) {
        const size_t child_side = current_side / 2;
        size_t next_count = 0;
        for (size_t parent = 0; parent < current_count; ++parent) {
            const size_t parent_row = current_rows[parent];
            const size_t parent_col = current_cols[parent];
            for (size_t quadrant = 0; quadrant < 4; ++quadrant) {
                const size_t child_row = parent_row + (quadrant / 2) * child_side;
                const size_t child_col = parent_col + (quadrant % 2) * child_side;
                const int occupied = block_nonempty(rows, n, child_row, child_col, child_side);
                if (level < height) {
                    if (occupied) {
                        bit_set(t_bits, t_used);
                        next_rows[next_count] = (uint8_t)child_row;
                        next_cols[next_count] = (uint8_t)child_col;
                        ++next_count;
                    }
                    ++t_used;
                } else {
                    if (occupied) bit_set(l_bits, l_used);
                    ++l_used;
                }
            }
        }
        if (level < height) {
            for (size_t i = 0; i < next_count; ++i) {
                current_rows[i] = next_rows[i];
                current_cols[i] = next_cols[i];
            }
            current_count = next_count;
            current_side = child_side;
        }
    }
    rank_prefix[0] = 0;
    for (size_t i = 0; i < t_used; ++i)
        rank_prefix[i + 1] = (uint16_t)(rank_prefix[i] + bit_get(t_bits, i));
    *t_length = t_used;
    *l_length = l_used;
    *height_out = height;
}

static int edge_query(const uint8_t *t_bits, const uint8_t *l_bits,
                      size_t t_length, const uint16_t *rank_prefix,
                      size_t height, size_t u, size_t v) {
    int64_t parent = -1;
    size_t row_start = 0, col_start = 0, side = (size_t)1 << height;
    for (size_t depth = 0; depth < height; ++depth) {
        const size_t child_side = side / 2;
        const size_t row_bit = u >= row_start + child_side;
        const size_t col_bit = v >= col_start + child_side;
        const size_t quadrant = 2 * row_bit + col_bit;
        const size_t child_base = parent < 0 ? 0 : 4 * rank_prefix[(size_t)parent + 1];
        const size_t child = child_base + quadrant;
        if (row_bit) row_start += child_side;
        if (col_bit) col_start += child_side;
        if (child < t_length) {
            if (!bit_get(t_bits, child)) return 0;
            parent = (int64_t)child;
        } else {
            return bit_get(l_bits, child - t_length);
        }
        side = child_side;
    }
    return 0;
}

static void put_i64_le(uint8_t *output, size_t offset, uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(value >> (byte * 8));
}

int64_t k2_tree_compact_graph(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length < (size_t)n_value + 2) return -1;
    const size_t n = (size_t)n_value;
    const uint64_t row_limit = (UINT64_C(1) << n) - 1;
    for (size_t row = 0; row < n; ++row)
        if (input[1 + row] < 0 || (uint64_t)input[1 + row] > row_limit) return -1;
    const size_t q_index = n + 1;
    const int64_t q_value = input[q_index];
    if (q_value < 0 || q_value > MAX_Q) return -1;
    const size_t q = (size_t)q_value;
    if (length != n + 2 + 3 * q) return -1;
    const size_t query_start = n + 2;
    for (size_t j = 0; j < q; ++j) {
        const int64_t op = input[query_start + 3 * j];
        const int64_t u = input[query_start + 3 * j + 1];
        const int64_t v = input[query_start + 3 * j + 2];
        if (u < 0 || (uint64_t)u >= n) return -1;
        if (op == 0) {
            if (v < 0 || (uint64_t)v >= n) return -1;
        } else if (op == 1) {
            if (v != 0) return -1;
        } else return -1;
    }

    const size_t output_bytes = 8 * (q + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t t_bits[T_BYTES] = {0}, l_bits[L_BYTES] = {0};
    uint16_t rank_prefix[T_MAX_BITS + 1] = {0};
    uint8_t current_rows[NODE_CAP] = {0}, current_cols[NODE_CAP] = {0};
    uint8_t next_rows[NODE_CAP] = {0}, next_cols[NODE_CAP] = {0};
    size_t t_length, l_length, height;
    build_tree(input + 1, n, t_bits, l_bits, rank_prefix, current_rows,
               current_cols, next_rows, next_cols, &t_length, &l_length, &height);
    (void)l_length;
    put_i64_le(output, 0, q);
    for (size_t j = 0; j < q; ++j) {
        const int64_t op = input[query_start + 3 * j];
        const size_t u = (size_t)input[query_start + 3 * j + 1];
        const size_t v = (size_t)input[query_start + 3 * j + 2];
        uint64_t result = 0;
        if (op == 0) {
            result = (uint64_t)edge_query(t_bits, l_bits, t_length, rank_prefix, height, u, v);
        } else {
            for (size_t successor = 0; successor < n; ++successor)
                if (edge_query(t_bits, l_bits, t_length, rank_prefix, height, u, successor))
                    result |= UINT64_C(1) << successor;
        }
        put_i64_le(output, 8 * (j + 1), result);
    }
    return (int64_t)output_bytes;
}
