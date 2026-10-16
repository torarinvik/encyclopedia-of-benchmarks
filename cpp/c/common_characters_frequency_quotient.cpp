#include <cstddef>
#include <cstdint>

extern "C" int64_t common_characters_frequency_quotient(
    const int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    constexpr std::size_t max_strings = 16, max_string_length = 64;
    constexpr std::size_t max_total = 512;
    if (input == nullptr || length < 1 || length > 1 + max_strings * (1 + max_string_length)) return -1;
    const int64_t string_count = input[0];
    if (string_count < 0 || string_count > static_cast<int64_t>(max_strings)) return -1;
    int64_t counts[26]{};
    std::size_t offset = 1, total = 0;
    for (int64_t string_index = 0; string_index < string_count; ++string_index) {
        if (offset >= length) return -1;
        const int64_t string_length = input[offset++];
        if (string_length < 0 || string_length > static_cast<int64_t>(max_string_length) ||
            static_cast<std::size_t>(string_length) > length - offset) return -1;
        for (int64_t i = 0; i < string_length; ++i) {
            const int64_t value = input[offset++];
            if (value < 'a' || value > 'z') return -1;
            ++counts[value - 'a'];
        }
        total += static_cast<std::size_t>(string_length);
        if (total > max_total) return -1;
    }
    if (offset != length) return -1;
    std::size_t used = 0;
    if (string_count > 0)
        for (std::size_t letter = 0; letter < 26; ++letter)
            used += static_cast<std::size_t>(counts[letter] / string_count);
    if (used > capacity || (used > 0 && output == nullptr)) return -2;
    std::size_t output_offset = 0;
    if (string_count > 0)
        for (std::size_t letter = 0; letter < 26; ++letter)
            for (int64_t copy = 0; copy < counts[letter] / string_count; ++copy)
                output[output_offset++] = static_cast<std::uint8_t>('a' + letter);
    return static_cast<int64_t>(used);
}
