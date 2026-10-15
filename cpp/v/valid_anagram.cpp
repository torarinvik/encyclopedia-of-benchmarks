// Compare lowercase ASCII strings by their letter frequencies.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 1024;
constexpr std::size_t max_input_length = 2 + 2 * max_string_length;
}

extern "C" std::int64_t valid_anagram(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t first_length_value = input[0];
    const std::int64_t second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > static_cast<std::int64_t>(max_string_length) ||
        second_length_value < 0 || second_length_value > static_cast<std::int64_t>(max_string_length)) return -1;
    const std::size_t first_length = static_cast<std::size_t>(first_length_value);
    const std::size_t second_length = static_cast<std::size_t>(second_length_value);
    if (length != 2 + first_length + second_length) return -1;
    std::size_t first_counts[26]{};
    std::size_t second_counts[26]{};
    for (std::size_t index = 0; index < first_length; ++index) {
        const std::int64_t value = input[2 + index];
        if (value < 'a' || value > 'z') return -1;
        ++first_counts[static_cast<std::size_t>(value - 'a')];
    }
    for (std::size_t index = 0; index < second_length; ++index) {
        const std::int64_t value = input[2 + first_length + index];
        if (value < 'a' || value > 'z') return -1;
        ++second_counts[static_cast<std::size_t>(value - 'a')];
    }
    for (std::size_t letter = 0; letter < 26; ++letter)
        if (first_counts[letter] != second_counts[letter]) return 0;
    return 1;
}
