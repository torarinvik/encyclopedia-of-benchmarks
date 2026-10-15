#include <array>
#include <cstddef>
#include <cstdint>

extern "C" int64_t close_strings(const int64_t *input, size_t length) {
    if (length < 2 || length > 514 || input == nullptr) return -1;
    const int64_t first_length_value = input[0];
    const int64_t second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > 256
            || second_length_value < 0 || second_length_value > 256
            || length != static_cast<size_t>(2 + first_length_value + second_length_value)) return -1;
    const size_t first_length = static_cast<size_t>(first_length_value);
    const size_t second_length = static_cast<size_t>(second_length_value);
    std::array<int64_t, 26> first{};
    std::array<int64_t, 26> second{};
    for (size_t index = 0; index < first_length; ++index) {
        const int64_t value = input[2 + index];
        if (value < 'a' || value > 'z') return -1;
        ++first[static_cast<size_t>(value - 'a')];
    }
    const size_t second_start = 2 + first_length;
    for (size_t index = 0; index < second_length; ++index) {
        const int64_t value = input[second_start + index];
        if (value < 'a' || value > 'z') return -1;
        ++second[static_cast<size_t>(value - 'a')];
    }
    if (first_length != second_length) return 0;
    std::array<int64_t, 257> first_frequency_counts{};
    std::array<int64_t, 257> second_frequency_counts{};
    for (size_t letter = 0; letter < 26; ++letter) {
        if ((first[letter] == 0) != (second[letter] == 0)) return 0;
        ++first_frequency_counts[static_cast<size_t>(first[letter])];
        ++second_frequency_counts[static_cast<size_t>(second[letter])];
    }
    return first_frequency_counts == second_frequency_counts ? 1 : 0;
}
