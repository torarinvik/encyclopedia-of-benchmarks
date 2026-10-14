#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 256;
constexpr std::size_t max_operations = 512;
constexpr std::size_t max_input_values = 2 + 3 * max_operations;
constexpr std::int64_t value_limit = 1'000'000;
constexpr std::int64_t query_offset = 131'072'000'001;
constexpr std::int64_t final_offset = 512'000'001;

std::size_t lowbit(std::size_t index) { return index & (~index + 1U); }

std::int64_t prefix_sum(const std::int64_t *tree, std::size_t count)
{
    std::int64_t sum = 0;
    while (count > 0) {
        sum += tree[count];
        count -= lowbit(count);
    }
    return sum;
}
}

extern "C" std::int64_t fenwick_tree_benchmark(const std::int64_t *values, std::size_t length)
{
    if (length < 2 || length > max_input_values) return -1;
    const std::int64_t item_count_value = values[0];
    const std::int64_t operation_count_value = values[1];
    if (item_count_value < 1 || item_count_value > static_cast<std::int64_t>(max_items) ||
        operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t item_count = static_cast<std::size_t>(item_count_value);
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    if (length != 2 + 3 * operation_count) return -1;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t position = 2 + 3 * operation;
        const std::int64_t opcode = values[position];
        const std::int64_t first = values[position + 1];
        const std::int64_t second = values[position + 2];
        if (opcode == 0) {
            if (first < 0 || first >= item_count_value || second < -value_limit || second > value_limit) return -1;
        } else if (opcode == 1) {
            if (first < 0 || second < first || second >= item_count_value) return -1;
        } else return -1;
    }

    std::int64_t data[max_items]{};
    std::int64_t tree[max_items + 1]{};
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t position = 2 + 3 * operation;
        const std::int64_t opcode = values[position];
        const std::size_t first = static_cast<std::size_t>(values[position + 1]);
        const std::int64_t second = values[position + 2];
        if (opcode == 0) {
            data[first] += second;
            for (std::size_t index = first + 1; index <= item_count; index += lowbit(index)) tree[index] += second;
        } else {
            const std::size_t right = static_cast<std::size_t>(second);
            const std::int64_t result = prefix_sum(tree, right + 1) - prefix_sum(tree, first);
            checksum += static_cast<std::int64_t>(operation + 1) * (result + query_offset);
        }
    }
    for (std::size_t i = 0; i < item_count; ++i) {
        checksum += static_cast<std::int64_t>(operation_count + i + 1) * (data[i] + final_offset);
    }
    return checksum;
}
