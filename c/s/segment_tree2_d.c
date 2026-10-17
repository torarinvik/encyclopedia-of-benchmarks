#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 16u
#define MAX_OPERATIONS 256u
#define MAX_PARSEABLE_INPUT_VALUES 1284u
#define MAX_TREE_NODES 32u
#define MAX_TREE_CELLS (MAX_TREE_NODES * MAX_TREE_NODES)
#define MIN_CELL_VALUE INT64_C(-1000)
#define MAX_CELL_VALUE INT64_C(1000)
#define CHECKSUM_OFFSET INT64_C(256001)

static size_t padded_size(size_t size)
{
    size_t result = 1u;
    while (result < size) result <<= 1u;
    return result;
}

static void update_columns(int32_t *tree, size_t row_node, size_t column_base,
                           size_t column, int32_t value)
{
    size_t node = column_base + column;
    tree[row_node * MAX_TREE_NODES + node] = value;
    while (node > 1u) {
        node >>= 1u;
        tree[row_node * MAX_TREE_NODES + node] =
            tree[row_node * MAX_TREE_NODES + 2u * node] +
            tree[row_node * MAX_TREE_NODES + 2u * node + 1u];
    }
}

static int64_t query_columns(const int32_t *tree, size_t row_node, size_t column_base,
                             size_t left, size_t right)
{
    left += column_base;
    right += column_base;
    int64_t sum = 0;
    while (left < right) {
        if ((left & 1u) != 0u) sum += tree[row_node * MAX_TREE_NODES + left++];
        if ((right & 1u) != 0u) sum += tree[row_node * MAX_TREE_NODES + --right];
        left >>= 1u;
        right >>= 1u;
    }
    return sum;
}

static void update_point(int32_t *tree, size_t row_base, size_t column_base,
                         size_t row, size_t column, int32_t value)
{
    size_t row_node = row_base + row;
    update_columns(tree, row_node, column_base, column, value);
    while (row_node > 1u) {
        row_node >>= 1u;
        const int32_t child_value =
            tree[(2u * row_node) * MAX_TREE_NODES + column_base + column] +
            tree[(2u * row_node + 1u) * MAX_TREE_NODES + column_base + column];
        update_columns(tree, row_node, column_base, column, child_value);
    }
}

static int64_t query_rectangle(const int32_t *tree, size_t row_base, size_t column_base,
                               size_t top, size_t bottom, size_t left, size_t right)
{
    size_t row_left = top + row_base;
    size_t row_right = bottom + row_base;
    int64_t sum = 0;
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

int64_t segment_tree2_d_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_DIMENSION ||
        input[1] < 1 || input[1] > (int64_t)MAX_DIMENSION) return -1;
    const size_t rows = (size_t)input[0];
    const size_t columns = (size_t)input[1];
    if (input[2] < 0 || input[2] > (int64_t)MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[2];
    if (3u + 5u * operation_count != length) return -1;

    const size_t row_base = padded_size(rows);
    const size_t column_base = padded_size(columns);
    int32_t tree[MAX_TREE_CELLS] = {0};
    size_t cursor = 3u;
    int64_t checksum = 0;
    for (size_t operation = 0u; operation < operation_count; ++operation) {
        const int64_t opcode = input[cursor++];
        const int64_t first = input[cursor++];
        const int64_t second = input[cursor++];
        const int64_t third = input[cursor++];
        const int64_t fourth = input[cursor++];

        if (opcode == 0) {
            if (first < 0 || first >= (int64_t)rows || second < 0 || second >= (int64_t)columns ||
                third < MIN_CELL_VALUE || third > MAX_CELL_VALUE || fourth != 0) return -1;
            update_point(tree, row_base, column_base, (size_t)first, (size_t)second, (int32_t)third);
        } else if (opcode == 1) {
            if (first < 0 || first > second || second > (int64_t)rows ||
                third < 0 || third > fourth || fourth > (int64_t)columns) return -1;
            const int64_t result = query_rectangle(tree, row_base, column_base,
                (size_t)first, (size_t)second, (size_t)third, (size_t)fourth);
            checksum += (int64_t)(operation + 1u) * (result + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return checksum;
}
