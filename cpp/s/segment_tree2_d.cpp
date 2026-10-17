#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_dimension = 16;
constexpr std::size_t max_operations = 256;
constexpr std::size_t max_parseable_input_values = 1284;
constexpr std::size_t max_tree_nodes = 32;
constexpr std::int64_t min_cell_value = -1'000;
constexpr std::int64_t max_cell_value = 1'000;
constexpr std::int64_t checksum_offset = 256'001;

std::size_t padded_size(std::size_t size)
{
    std::size_t result = 1;
    while (result < size) result <<= 1u;
    return result;
}

void update_columns(std::int32_t *tree, std::size_t row_node, std::size_t column_base,
                    std::size_t column, std::int32_t value)
{
    std::size_t node = column_base + column;
    tree[row_node * max_tree_nodes + node] = value;
    while (node > 1) {
        node >>= 1u;
        tree[row_node * max_tree_nodes + node] =
            tree[row_node * max_tree_nodes + 2 * node] +
            tree[row_node * max_tree_nodes + 2 * node + 1];
    }
}

std::int64_t query_columns(const std::int32_t *tree, std::size_t row_node,
                           std::size_t column_base, std::size_t left, std::size_t right)
{
    left += column_base;
    right += column_base;
    std::int64_t sum = 0;
    while (left < right) {
        if ((left & 1u) != 0u) sum += tree[row_node * max_tree_nodes + left++];
        if ((right & 1u) != 0u) sum += tree[row_node * max_tree_nodes + --right];
        left >>= 1u;
        right >>= 1u;
    }
    return sum;
}

void update_point(std::int32_t *tree, std::size_t row_base, std::size_t column_base,
                  std::size_t row, std::size_t column, std::int32_t value)
{
    std::size_t row_node = row_base + row;
    update_columns(tree, row_node, column_base, column, value);
    while (row_node > 1) {
        row_node >>= 1u;
        const std::int32_t child_value =
            tree[(2 * row_node) * max_tree_nodes + column_base + column] +
            tree[(2 * row_node + 1) * max_tree_nodes + column_base + column];
        update_columns(tree, row_node, column_base, column, child_value);
    }
}

std::int64_t query_rectangle(const std::int32_t *tree, std::size_t row_base,
                             std::size_t column_base, std::size_t top,
                             std::size_t bottom, std::size_t left, std::size_t right)
{
    std::size_t row_left = top + row_base;
    std::size_t row_right = bottom + row_base;
    std::int64_t sum = 0;
    while (row_left < row_right) {
        if ((row_left & 1u) != 0u)
            sum += query_columns(tree, row_left++, column_base, left, right);
        if ((row_right & 1u) != 0u)
            sum += query_columns(tree, --row_right, column_base, left, right);
        row_left >>= 1u;
        row_right >>= 1u;
    }
    return sum;
}
}

extern "C" std::int64_t segment_tree2_d_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 3 || length > max_parseable_input_values) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_dimension) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_dimension)) return -1;
    const std::size_t rows = static_cast<std::size_t>(input[0]);
    const std::size_t columns = static_cast<std::size_t>(input[1]);
    if (input[2] < 0 || input[2] > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(input[2]);
    if (3 + 5 * operation_count != length) return -1;

    const std::size_t row_base = padded_size(rows);
    const std::size_t column_base = padded_size(columns);
    std::int32_t tree[max_tree_nodes * max_tree_nodes] = {};
    std::size_t cursor = 3;
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[cursor++];
        const std::int64_t first = input[cursor++];
        const std::int64_t second = input[cursor++];
        const std::int64_t third = input[cursor++];
        const std::int64_t fourth = input[cursor++];
        if (opcode == 0) {
            if (first < 0 || first >= static_cast<std::int64_t>(rows) ||
                second < 0 || second >= static_cast<std::int64_t>(columns) ||
                third < min_cell_value || third > max_cell_value || fourth != 0) return -1;
            update_point(tree, row_base, column_base, static_cast<std::size_t>(first),
                         static_cast<std::size_t>(second), static_cast<std::int32_t>(third));
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > static_cast<std::int64_t>(rows) ||
                third < 0 || third > fourth || fourth > static_cast<std::int64_t>(columns)) return -1;
            const std::int64_t result = query_rectangle(tree, row_base, column_base,
                static_cast<std::size_t>(first), static_cast<std::size_t>(second),
                static_cast<std::size_t>(third), static_cast<std::size_t>(fourth));
            checksum += static_cast<std::int64_t>(operation + 1) * (result + checksum_offset);
        } else {
            return -1;
        }
    }
    return checksum;
}
