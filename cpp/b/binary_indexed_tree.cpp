#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 256, max_operations = 512;
constexpr std::size_t max_input_values = 2 + 3 * max_operations;
constexpr std::int64_t value_limit = 1'000'000, query_offset = 131'072'000'001, final_offset = 512'000'001;
int lowbit(int index) noexcept { return index & -index; }
std::int32_t prefix_sum(const std::int32_t *tree, int count) noexcept {
    std::int32_t sum = 0;
    while (count > 0) { sum += tree[count]; count -= lowbit(count); }
    return sum;
}
}

extern "C" std::int64_t binary_indexed_tree(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length < 2 || length > max_input_values) return -1;
    const auto n_value = values[0], op_value = values[1];
    if (n_value < 2 || n_value > static_cast<std::int64_t>(max_items) || (n_value & (n_value - 1)) != 0 || op_value < 0 || op_value > static_cast<std::int64_t>(max_operations)) return -1;
    const auto n = static_cast<std::size_t>(n_value), operations = static_cast<std::size_t>(op_value);
    if (length != 2 + 3 * operations) return -1;
    for (std::size_t op = 0; op < operations; ++op) {
        const auto at = 2 + 3 * op;
        const auto code = values[at], first = values[at + 1], second = values[at + 2];
        if (code == 0) { if (first < 0 || first >= n_value || second < -value_limit || second > value_limit) return -1; }
        else if (code == 1) { if (first < 0 || second < first || second >= n_value) return -1; }
        else return -1;
    }
    std::int32_t data[max_items]{}, tree[max_items + 2]{};
    std::int64_t checksum = 0;
    for (std::size_t op = 0; op < operations; ++op) {
        const auto at = 2 + 3 * op;
        const int code = static_cast<int>(values[at]), first = static_cast<int>(values[at + 1]);
        const auto second = static_cast<std::int32_t>(values[at + 2]);
        if (code == 0) {
            data[first] += second;
            int start = first + 1;
            while (start <= static_cast<int>(n) + 1) { tree[start] += second; start += lowbit(start); }
        } else {
            const auto result = prefix_sum(tree, static_cast<int>(second) + 1) - prefix_sum(tree, first);
            checksum += static_cast<std::int64_t>(op + 1) * (static_cast<std::int64_t>(result) + query_offset);
        }
    }
    for (std::size_t i = 0; i < n; ++i) checksum += static_cast<std::int64_t>(operations + i + 1) * (static_cast<std::int64_t>(data[i]) + final_offset);
    return checksum;
}
