// Case-insensitive anagram check for distinct ASCII alphabetic strings.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_string_length = 1024;
constexpr std::size_t max_input_length = 2 + 2 * max_string_length;
int letter_index(std::int64_t value) noexcept {
    if (value >= 'a' && value <= 'z') return static_cast<int>(value - 'a');
    if (value >= 'A' && value <= 'Z') return static_cast<int>(value - 'A');
    return -1;
}
}

extern "C" std::int64_t check_anagram(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const std::int64_t first_length_value = input[0], second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 1024 ||
        second_length_value < 0 || second_length_value > 1024) return -1;
    const std::size_t first_length = static_cast<std::size_t>(first_length_value);
    const std::size_t second_length = static_cast<std::size_t>(second_length_value);
    if (length != 2 + first_length + second_length) return -1;
    std::size_t first_counts[26]{}, second_counts[26]{};
    for (std::size_t index = 0; index < first_length; ++index) {
        const int letter = letter_index(input[2 + index]);
        if (letter < 0) return -1;
        ++first_counts[letter];
    }
    for (std::size_t index = 0; index < second_length; ++index) {
        const int letter = letter_index(input[2 + first_length + index]);
        if (letter < 0) return -1;
        ++second_counts[letter];
    }
    if (first_length != second_length) return 0;
    bool different_after_normalization = false;
    for (std::size_t index = 0; index < first_length; ++index)
        if (letter_index(input[2 + index]) != letter_index(input[2 + first_length + index]))
            different_after_normalization = true;
    if (!different_after_normalization) return 0;
    for (std::size_t letter = 0; letter < 26; ++letter)
        if (first_counts[letter] != second_counts[letter]) return 0;
    return 1;
}
