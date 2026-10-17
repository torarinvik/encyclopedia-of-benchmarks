#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 64;
constexpr std::size_t max_operations = 20;
constexpr std::size_t max_parseable_input_values = 147;
constexpr std::size_t max_tree_size = 128;
constexpr std::int64_t min_initial_value = -1;
constexpr std::int64_t max_initial_value = 1;
constexpr std::int64_t min_multiplier = -2;
constexpr std::int64_t max_multiplier = 2;
constexpr std::int64_t checksum_offset = 67'108'865;

std::size_t padded_size(std::size_t length)
{
    std::size_t result = 1;
    while (result < length) result <<= 1u;
    return result;
}

void apply_range(std::int32_t *tree, std::int32_t *operand, int left, int right,
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

std::int32_t query_range(const std::int32_t *tree, const std::int32_t *operand,
                         int left, int right, int segment_left, int segment_right, int node)
{
    if (left <= segment_left && segment_right <= right) return tree[node];
    if (right < segment_left || segment_right < left) return 0;
    const int middle = (segment_left + segment_right) / 2;
    const std::int32_t child_sum =
        query_range(tree, operand, left, right, segment_left, middle, 2 * node) +
        query_range(tree, operand, left, right, middle + 1, segment_right, 2 * node + 1);
    return operand[node] * child_sum;
}
}

extern "C" std::int64_t segment_tree_apply_benchmark(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 2 || length > max_parseable_input_values) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_length)) return -1;
    const std::size_t array_length = static_cast<std::size_t>(input[0]);
    if (length < array_length + 2) return -1;
    for (std::size_t index = 0; index < array_length; ++index)
        if (input[index + 1] < min_initial_value || input[index + 1] > max_initial_value) return -1;
    const std::int64_t operation_count_value = input[array_length + 1];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    std::size_t cursor = array_length + 2;
    if (cursor + 4 * operation_count != length) return -1;

    const std::size_t base = padded_size(array_length);
    std::int32_t tree[max_tree_size] = {};
    std::int32_t operand[max_tree_size];
    for (std::size_t node = 0; node < max_tree_size; ++node) operand[node] = 1;
    for (std::size_t index = 0; index < array_length; ++index)
        tree[base + index] = static_cast<std::int32_t>(input[index + 1]);
    for (std::size_t node = base - 1; node > 0; --node)
        tree[node] = tree[2 * node] + tree[2 * node + 1];

    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::int64_t opcode = input[cursor++];
        const std::int64_t left_value = input[cursor++];
        const std::int64_t right_value = input[cursor++];
        const std::int64_t argument = input[cursor++];
        if (left_value < 0 || left_value > right_value || right_value >= static_cast<std::int64_t>(array_length))
            return -1;
        if (opcode == 0) {
            if (argument < min_multiplier || argument > max_multiplier) return -1;
            apply_range(tree, operand, static_cast<int>(left_value) + 1,
                        static_cast<int>(right_value) + 1, static_cast<int>(argument),
                        1, static_cast<int>(base), 1);
        } else if (opcode == 1) {
            if (argument != 0) return -1;
            const std::int32_t result = query_range(tree, operand,
                static_cast<int>(left_value) + 1, static_cast<int>(right_value) + 1,
                1, static_cast<int>(base), 1);
            checksum += static_cast<std::int64_t>(operation + 1) *
                        (static_cast<std::int64_t>(result) + checksum_offset);
        } else {
            return -1;
        }
    }
    return checksum;
}
