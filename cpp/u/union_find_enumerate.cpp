/* Union-find with circular component-member enumeration. */
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr std::size_t max_items = 16;
constexpr std::size_t max_operations = 32;
constexpr std::size_t max_input_length = 99;

std::size_t find_root(std::int64_t *parent, std::size_t item) noexcept {
    std::size_t root = item;
    while (parent[root] >= 0) root = static_cast<std::size_t>(parent[root]);
    while (item != root) {
        const auto next_item = static_cast<std::size_t>(parent[item]);
        parent[item] = static_cast<std::int64_t>(root);
        item = next_item;
    }
    return root;
}

std::int64_t component_mask(const std::int64_t *successor, std::size_t start) noexcept {
    std::uint64_t mask = 0;
    auto item = start;
    do {
        mask |= std::uint64_t{1} << item;
        item = static_cast<std::size_t>(successor[item]);
    } while (item != start);
    return static_cast<std::int64_t>(mask);
}
}

extern "C" std::int64_t union_find_enumerate(const std::int64_t *input,
                                               std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto item_count_value = input[0];
    const auto operation_count_value = input[1];
    if (item_count_value < 1 || item_count_value > static_cast<std::int64_t>(max_items) ||
        operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;
    const auto item_count = static_cast<std::size_t>(item_count_value);
    const auto operation_count = static_cast<std::size_t>(operation_count_value);
    if (length != 2 + 3 * operation_count) return -1;

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto position = 2 + 3 * operation;
        const auto opcode = input[position];
        const auto first = input[position + 1];
        const auto second = input[position + 2];
        if (opcode == 0) {
            if (first < 0 || first >= item_count_value || second < 0 || second >= item_count_value) return -1;
        } else if (opcode == 1) {
            if (first < 0 || first >= item_count_value || second != 0) return -1;
        } else return -1;
    }

    std::int64_t parent[max_items];
    std::int64_t successor[max_items];
    for (std::size_t item = 0; item < item_count; ++item) {
        parent[item] = -1;
        successor[item] = static_cast<std::int64_t>(item);
    }
    std::int64_t checksum = 0;
    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto position = 2 + 3 * operation;
        const auto opcode = input[position];
        const auto first = static_cast<std::size_t>(input[position + 1]);
        std::int64_t observed;
        if (opcode == 0) {
            auto left = find_root(parent, first);
            auto right = find_root(parent, static_cast<std::size_t>(input[position + 2]));
            observed = 0;
            if (left != right) {
                if (parent[left] > parent[right]) std::swap(left, right);
                parent[left] += parent[right];
                parent[right] = static_cast<std::int64_t>(left);
                std::swap(successor[left], successor[right]);
                observed = 1;
            }
        } else {
            observed = component_mask(successor, first);
        }
        checksum += static_cast<std::int64_t>(operation + 1) * (observed + 1);
    }
    return checksum;
}
