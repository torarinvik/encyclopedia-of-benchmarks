// Check for a permutation of one lowercase ASCII string inside another.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 1024;
constexpr std::size_t max_input_length = 2 + 2 * max_string_length;

void adjust_count(std::int64_t differences[26], std::int64_t &nonzero,
                  std::size_t letter, std::int64_t amount) noexcept {
    if (differences[letter] == 0) ++nonzero;
    differences[letter] += amount;
    if (differences[letter] == 0) --nonzero;
}
}

extern "C" std::int64_t permutation_in_string(const std::int64_t *input,
                                                std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t first_length_value = input[0], second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > static_cast<std::int64_t>(max_string_length) ||
        second_length_value < 0 || second_length_value > static_cast<std::int64_t>(max_string_length)) return -1;
    const std::size_t first_length = static_cast<std::size_t>(first_length_value);
    const std::size_t second_length = static_cast<std::size_t>(second_length_value);
    if (length != 2 + first_length + second_length) return -1;
    for (std::size_t index = 2; index < length; ++index)
        if (input[index] < 'a' || input[index] > 'z') return -1;
    if (first_length > second_length) return 0;

    std::int64_t differences[26]{};
    std::int64_t nonzero = 0;
    for (std::size_t index = 0; index < first_length; ++index) {
        adjust_count(differences, nonzero, static_cast<std::size_t>(input[2 + index] - 'a'), 1);
        adjust_count(differences, nonzero,
                     static_cast<std::size_t>(input[2 + first_length + index] - 'a'), -1);
    }
    if (nonzero == 0) return 1;
    for (std::size_t start = 0; start < second_length - first_length; ++start) {
        const std::size_t outgoing = 2 + first_length + start;
        const std::size_t incoming = outgoing + first_length;
        adjust_count(differences, nonzero, static_cast<std::size_t>(input[outgoing] - 'a'), 1);
        adjust_count(differences, nonzero, static_cast<std::size_t>(input[incoming] - 'a'), -1);
        if (nonzero == 0) return 1;
    }
    return 0;
}
