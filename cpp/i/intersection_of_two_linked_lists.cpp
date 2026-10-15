// Find the first shared node identity by switching traversal heads.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_list_length = 1024;
constexpr std::size_t max_input_length = 2 + 2 * max_list_length;
}

extern "C" std::int64_t intersection_of_two_linked_lists(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -2;
    const auto first_length_value = input[0], second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 1024 ||
        second_length_value < 0 || second_length_value > 1024) return -2;
    const auto first_length = static_cast<std::size_t>(first_length_value);
    const auto second_length = static_cast<std::size_t>(second_length_value);
    if (length != 2 + first_length + second_length) return -2;
    for (std::size_t index = 2; index < length; ++index)
        if (input[index] < 0 || input[index] > INT32_MAX) return -2;
    if (first_length == 0 || second_length == 0) return -1;

    std::size_t first_position = 0, second_position = 0;
    bool first_on_first_list = true, second_on_first_list = false;
    for (std::size_t step = 0; step <= first_length + second_length; ++step) {
        const std::size_t first_base = first_on_first_list ? 2 : 2 + first_length;
        const std::size_t first_source_length = first_on_first_list ? first_length : second_length;
        const std::size_t second_base = second_on_first_list ? 2 : 2 + first_length;
        const std::size_t second_source_length = second_on_first_list ? first_length : second_length;
        const auto first_node = input[first_base + first_position];
        const auto second_node = input[second_base + second_position];
        if (first_node == second_node) return first_node;

        ++first_position;
        ++second_position;
        const bool first_is_null = first_position == first_source_length;
        const bool second_is_null = second_position == second_source_length;
        if (first_is_null && second_is_null) return -1;
        if (first_is_null) { first_on_first_list = !first_on_first_list; first_position = 0; }
        if (second_is_null) { second_on_first_list = !second_on_first_list; second_position = 0; }
    }
    return -1;
}
