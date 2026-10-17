#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64u
#define MAX_OPERATIONS 20u
#define MAX_PARSEABLE_INPUT_VALUES 147u
#define MAX_TREE_SIZE (2u * MAX_LENGTH)
#define MIN_INITIAL_VALUE INT64_C(-1)
#define MAX_INITIAL_VALUE INT64_C(1)
#define MIN_MULTIPLIER INT64_C(-2)
#define MAX_MULTIPLIER INT64_C(2)
#define CHECKSUM_OFFSET INT64_C(67108865)

static size_t padded_size(size_t length)
{
    size_t result = 1u;
    while (result < length) result <<= 1u;
    return result;
}

static void apply_range(int32_t *tree, int32_t *operand, int left, int right,
                        int multiplier, int segment_left, int segment_right, int node)
{
    if (left <= segment_left && segment_right <= right) {
        operand[node] *= multiplier;
        tree[node] *= multiplier;
        return;
    }
    if (right < segment_left || segment_right < left) return;
    const int middle = (segment_left + segment_right) / 2;
    apply_range(tree, operand, left, right, multiplier, segment_left, middle, 2 * node);
    apply_range(tree, operand, left, right, multiplier, middle + 1, segment_right, 2 * node + 1);
    tree[node] = operand[node] * (tree[2 * node] + tree[2 * node + 1]);
}

static int32_t query_range(const int32_t *tree, const int32_t *operand,
                           int left, int right, int segment_left, int segment_right, int node)
{
    if (left <= segment_left && segment_right <= right) return tree[node];
    if (right < segment_left || segment_right < left) return 0;
    const int middle = (segment_left + segment_right) / 2;
    const int32_t child_sum =
        query_range(tree, operand, left, right, segment_left, middle, 2 * node) +
        query_range(tree, operand, left, right, middle + 1, segment_right, 2 * node + 1);
    return operand[node] * child_sum;
}

int64_t segment_tree_apply_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT_VALUES) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_LENGTH) return -1;
    const size_t array_length = (size_t)input[0];
    if (length < array_length + 2u) return -1;

    for (size_t index = 0u; index < array_length; ++index)
        if (input[index + 1u] < MIN_INITIAL_VALUE || input[index + 1u] > MAX_INITIAL_VALUE) return -1;
    const int64_t operation_count_value = input[array_length + 1u];
    if (operation_count_value < 0 || operation_count_value > (int64_t)MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)operation_count_value;
    size_t cursor = array_length + 2u;
    if (cursor + 4u * operation_count != length) return -1;

    const size_t base = padded_size(array_length);
    int32_t tree[MAX_TREE_SIZE] = {0};
    int32_t operand[MAX_TREE_SIZE];
    for (size_t node = 0u; node < MAX_TREE_SIZE; ++node) operand[node] = 1;
    for (size_t index = 0u; index < array_length; ++index)
        tree[base + index] = (int32_t)input[index + 1u];
    for (size_t node = base - 1u; node > 0u; --node)
        tree[node] = tree[2u * node] + tree[2u * node + 1u];

    int64_t checksum = 0;
    for (size_t operation = 0u; operation < operation_count; ++operation) {
        const int64_t opcode = input[cursor++];
        const int64_t left_value = input[cursor++];
        const int64_t right_value = input[cursor++];
        const int64_t argument = input[cursor++];
        if (left_value < 0 || left_value > right_value || right_value >= (int64_t)array_length)
            return -1;
        if (opcode == 0) {
            if (argument < MIN_MULTIPLIER || argument > MAX_MULTIPLIER) return -1;
            apply_range(tree, operand, (int)left_value + 1, (int)right_value + 1,
                        (int)argument, 1, (int)base, 1);
        } else if (opcode == 1) {
            if (argument != 0) return -1;
            const int32_t result = query_range(tree, operand,
                (int)left_value + 1, (int)right_value + 1, 1, (int)base, 1);
            checksum += (int64_t)(operation + 1u) * ((int64_t)result + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return checksum;
}
