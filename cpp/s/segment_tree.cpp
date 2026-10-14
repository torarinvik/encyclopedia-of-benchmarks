#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ITEMS = 256;
constexpr std::size_t MAX_OPERATIONS = 512;
constexpr std::size_t MAX_INPUT_VALUES = MAX_ITEMS + 3 + 3 * MAX_OPERATIONS;
constexpr std::int64_t VALUE_LIMIT = 1'000'000;
constexpr std::int64_t QUERY_OFFSET = 256'000'001;
constexpr std::int64_t FINAL_OFFSET = 1'000'001;

std::int64_t identity(std::int64_t mode) noexcept
{
    if (mode == 1) return VALUE_LIMIT + 1;
    if (mode == 2) return -(VALUE_LIMIT + 1);
    return 0;
}

std::int64_t combine(std::int64_t mode, std::int64_t left, std::int64_t right) noexcept
{
    if (mode == 1) return left < right ? left : right;
    if (mode == 2) return left > right ? left : right;
    return left + right;
}
} // namespace

extern "C" std::int64_t segment_tree_benchmark(const std::int64_t *values,
                                                std::size_t length) noexcept
{
    if (length < 3 || length > MAX_INPUT_VALUES) return -1;
    const std::int64_t mode = values[0];
    const std::int64_t item_count_value = values[1];
    if (mode < 0 || mode > 2 || item_count_value < 1 || item_count_value > MAX_ITEMS) return -1;
    const auto item_count = static_cast<std::size_t>(item_count_value);
    if (length < item_count + 3) return -1;
    const std::int64_t operation_count_value = values[item_count + 2];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS) return -1;
    const auto operation_count = static_cast<std::size_t>(operation_count_value);
    if (length != item_count + 3 + 3 * operation_count) return -1;

    std::int64_t data[MAX_ITEMS]{};
    for (std::size_t i = 0; i < item_count; ++i) {
        const std::int64_t value = values[i + 2];
        if (value < -VALUE_LIMIT || value > VALUE_LIMIT) return -1;
        data[i] = value;
    }
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t position = item_count + 3 + 3 * operation;
        const std::int64_t opcode = values[position];
        const std::int64_t first = values[position + 1];
        const std::int64_t second = values[position + 2];
        if (opcode == 0) {
            if (first < 0 || first >= item_count_value || second < -VALUE_LIMIT || second > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (first < 0 || second < first || second >= item_count_value) return -1;
        } else {
            return -1;
        }
    }

    std::size_t base = 1;
    while (base < item_count) base *= 2;
    std::int64_t tree[2 * MAX_ITEMS]{};
    const std::int64_t empty = identity(mode);
    for (std::size_t i = 0; i < 2 * base; ++i) tree[i] = empty;
    for (std::size_t i = 0; i < item_count; ++i) tree[base + i] = data[i];
    for (std::size_t node = base; node-- > 1;) {
        tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
    }

    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const std::size_t position = item_count + 3 + 3 * operation;
        const std::int64_t opcode = values[position];
        const auto first = static_cast<std::size_t>(values[position + 1]);
        if (opcode == 0) {
            const std::int64_t value = values[position + 2];
            data[first] = value;
            std::size_t node = base + first;
            tree[node] = value;
            while (node > 1) {
                node /= 2;
                tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
            }
        } else {
            std::size_t left = base + first;
            std::size_t right = base + static_cast<std::size_t>(values[position + 2]) + 1;
            std::int64_t result = empty;
            while (left < right) {
                if (left & 1U) result = combine(mode, result, tree[left++]);
                if (right & 1U) result = combine(mode, result, tree[--right]);
                left /= 2;
                right /= 2;
            }
            checksum += static_cast<std::int64_t>(operation + 1) * (result + QUERY_OFFSET);
        }
    }
    for (std::size_t i = 0; i < item_count; ++i) {
        checksum += static_cast<std::int64_t>(operation_count + i + 1) * (data[i] + FINAL_OFFSET);
    }
    return checksum;
}
