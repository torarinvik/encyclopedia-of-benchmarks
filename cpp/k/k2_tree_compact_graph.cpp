/* Clean-room bounded packed k²-tree graph query profile. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 32;
constexpr std::size_t max_q = 128;
constexpr std::size_t max_input = 419;
constexpr std::size_t t_max_bits = 340;
constexpr std::size_t l_max_bits = 1024;
constexpr std::size_t t_bytes = 43;
constexpr std::size_t l_bytes = 128;
constexpr std::size_t node_cap = 256;

std::uint8_t bit_get(const std::uint8_t *bits, std::size_t index) {
    return static_cast<std::uint8_t>((bits[index >> 3] >> (index & 7)) & 1u);
}

void bit_set(std::uint8_t *bits, std::size_t index) {
    bits[index >> 3] |= static_cast<std::uint8_t>(1u << (index & 7));
}

bool block_nonempty(const std::int64_t *rows, std::size_t n,
                    std::size_t row_start, std::size_t col_start, std::size_t side) {
    const auto column_mask = ((UINT64_C(1) << side) - 1) << col_start;
    for (std::size_t row = row_start; row < row_start + side; ++row)
        if (row < n && (static_cast<std::uint64_t>(rows[row]) & column_mask) != 0) return true;
    return false;
}

void build_tree(const std::int64_t *rows, std::size_t n,
                std::uint8_t *t_bits, std::uint8_t *l_bits, std::uint16_t *rank_prefix,
                std::uint8_t *current_rows, std::uint8_t *current_cols,
                std::uint8_t *next_rows, std::uint8_t *next_cols,
                std::size_t &t_length, std::size_t &l_length, std::size_t &height) {
    std::size_t side = 2;
    height = 1;
    while (side < n) { side <<= 1; ++height; }
    std::size_t current_count = 1, current_side = side;
    std::size_t t_used = 0, l_used = 0;
    current_rows[0] = 0;
    current_cols[0] = 0;
    for (std::size_t level = 1; level <= height; ++level) {
        const auto child_side = current_side / 2;
        std::size_t next_count = 0;
        for (std::size_t parent = 0; parent < current_count; ++parent) {
            const auto parent_row = current_rows[parent];
            const auto parent_col = current_cols[parent];
            for (std::size_t quadrant = 0; quadrant < 4; ++quadrant) {
                const auto child_row = parent_row + (quadrant / 2) * child_side;
                const auto child_col = parent_col + (quadrant % 2) * child_side;
                const bool occupied = block_nonempty(rows, n, child_row, child_col, child_side);
                if (level < height) {
                    if (occupied) {
                        bit_set(t_bits, t_used);
                        next_rows[next_count] = static_cast<std::uint8_t>(child_row);
                        next_cols[next_count] = static_cast<std::uint8_t>(child_col);
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
            for (std::size_t i = 0; i < next_count; ++i) {
                current_rows[i] = next_rows[i];
                current_cols[i] = next_cols[i];
            }
            current_count = next_count;
            current_side = child_side;
        }
    }
    rank_prefix[0] = 0;
    for (std::size_t i = 0; i < t_used; ++i)
        rank_prefix[i + 1] = static_cast<std::uint16_t>(rank_prefix[i] + bit_get(t_bits, i));
    t_length = t_used;
    l_length = l_used;
}

bool edge_query(const std::uint8_t *t_bits, const std::uint8_t *l_bits,
                std::size_t t_length, const std::uint16_t *rank_prefix,
                std::size_t height, std::size_t u, std::size_t v) {
    std::int64_t parent = -1;
    std::size_t row_start = 0, col_start = 0, side = std::size_t(1) << height;
    for (std::size_t depth = 0; depth < height; ++depth) {
        const auto child_side = side / 2;
        const auto row_bit = u >= row_start + child_side;
        const auto col_bit = v >= col_start + child_side;
        const auto quadrant = 2 * row_bit + col_bit;
        const auto child_base = parent < 0 ? 0 : 4 * rank_prefix[static_cast<std::size_t>(parent) + 1];
        const auto child = child_base + quadrant;
        if (row_bit) row_start += child_side;
        if (col_bit) col_start += child_side;
        if (child < t_length) {
            if (!bit_get(t_bits, child)) return false;
            parent = static_cast<std::int64_t>(child);
        } else {
            return bit_get(l_bits, child - t_length) != 0;
        }
        side = child_side;
    }
    return false;
}

void put_i64_le(std::uint8_t *output, std::size_t offset, std::uint64_t value) {
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (byte * 8));
}
}

extern "C" std::int64_t k2_tree_compact_graph(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0];
    if (n_value < 1 || n_value > static_cast<std::int64_t>(max_n)
        || length < static_cast<std::size_t>(n_value) + 2) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto row_limit = (UINT64_C(1) << n) - 1;
    for (std::size_t row = 0; row < n; ++row)
        if (input[1 + row] < 0 || static_cast<std::uint64_t>(input[1 + row]) > row_limit) return -1;
    const auto q_index = n + 1;
    const auto q_value = input[q_index];
    if (q_value < 0 || q_value > static_cast<std::int64_t>(max_q)) return -1;
    const auto q = static_cast<std::size_t>(q_value);
    if (length != n + 2 + 3 * q) return -1;
    const auto query_start = n + 2;
    for (std::size_t j = 0; j < q; ++j) {
        const auto op = input[query_start + 3 * j];
        const auto u = input[query_start + 3 * j + 1];
        const auto v = input[query_start + 3 * j + 2];
        if (u < 0 || static_cast<std::uint64_t>(u) >= n) return -1;
        if (op == 0) {
            if (v < 0 || static_cast<std::uint64_t>(v) >= n) return -1;
        } else if (op == 1) {
            if (v != 0) return -1;
        } else return -1;
    }
    const auto output_bytes = 8 * (q + 1);
    if (output == nullptr || capacity < output_bytes) return -2;

    std::uint8_t t_bits[t_bytes] = {}, l_bits[l_bytes] = {};
    std::uint16_t rank_prefix[t_max_bits + 1] = {};
    std::uint8_t current_rows[node_cap] = {}, current_cols[node_cap] = {};
    std::uint8_t next_rows[node_cap] = {}, next_cols[node_cap] = {};
    std::size_t t_length = 0, l_length = 0, height = 0;
    build_tree(input + 1, n, t_bits, l_bits, rank_prefix, current_rows,
               current_cols, next_rows, next_cols, t_length, l_length, height);
    (void)l_length;
    put_i64_le(output, 0, static_cast<std::uint64_t>(q));
    for (std::size_t j = 0; j < q; ++j) {
        const auto op = input[query_start + 3 * j];
        const auto u = static_cast<std::size_t>(input[query_start + 3 * j + 1]);
        const auto v = static_cast<std::size_t>(input[query_start + 3 * j + 2]);
        std::uint64_t result = 0;
        if (op == 0) {
            result = static_cast<std::uint64_t>(edge_query(t_bits, l_bits, t_length,
                                                          rank_prefix, height, u, v));
        } else {
            for (std::size_t successor = 0; successor < n; ++successor)
                if (edge_query(t_bits, l_bits, t_length, rank_prefix, height, u, successor))
                    result |= UINT64_C(1) << successor;
        }
        put_i64_le(output, 8 * (j + 1), result);
    }
    return static_cast<std::int64_t>(output_bytes);
}
