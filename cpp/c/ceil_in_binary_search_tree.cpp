#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_node_count = 127;
constexpr std::size_t max_input_length = 3 + 3 * max_node_count;
constexpr std::int64_t value_min = -1000000;
constexpr std::int64_t value_max = 1000000;
constexpr std::int64_t invalid_result = INT64_MIN + 1;
constexpr std::int64_t no_ceil_result = INT64_MIN;
}

extern "C" std::int64_t ceil_in_binary_search_tree(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > max_input_length) return invalid_result;
    const auto node_count_value = input[0];
    const auto root_index_value = input[1];
    const auto key = input[2];
    if (node_count_value < 0 || node_count_value > static_cast<std::int64_t>(max_node_count) ||
        key < value_min || key > value_max) return invalid_result;
    const auto node_count = static_cast<std::size_t>(node_count_value);
    if (length != 3 + 3 * node_count) return invalid_result;
    if (node_count == 0) return root_index_value == -1 ? no_ceil_result : invalid_result;
    if (root_index_value < 0 || root_index_value >= node_count_value) return invalid_result;

    auto current = static_cast<std::size_t>(root_index_value);
    auto best = no_ceil_result;
    for (std::size_t steps = 0; current != static_cast<std::size_t>(-1); ++steps) {
        if (steps >= node_count) return invalid_result;
        const auto offset = 3 + 3 * current;
        const auto value = input[offset];
        const auto left = input[offset + 1];
        const auto right = input[offset + 2];
        if (value < value_min || value > value_max || left < -1 || right < -1 ||
            left >= node_count_value || right >= node_count_value) return invalid_result;
        if (value == key) return value;
        if (value < key) current = right == -1 ? static_cast<std::size_t>(-1) : static_cast<std::size_t>(right);
        else {
            best = value;
            current = left == -1 ? static_cast<std::size_t>(-1) : static_cast<std::size_t>(left);
        }
    }
    return best;
}
