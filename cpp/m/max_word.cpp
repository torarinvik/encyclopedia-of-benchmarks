#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 512;
constexpr std::size_t max_input_length = max_text_length + 2;

std::uint8_t lower_ascii(std::uint8_t value) noexcept
{
    return value >= 'A' && value <= 'Z' ? static_cast<std::uint8_t>(value + ('a' - 'A')) : value;
}
}

extern "C" std::int64_t max_word(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto text_length_value = input[0];
    if (text_length_value < 1 || text_length_value > static_cast<std::int64_t>(max_text_length) ||
        length != 1 + static_cast<std::size_t>(text_length_value)) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    std::uint8_t text[max_text_length];
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[i + 1];
        const bool is_letter = (value >= 65 && value <= 90) || (value >= 97 && value <= 122);
        if (value == ' ') {
            if (i == 0 || i + 1 == text_length || text[i - 1] == ' ') return -1;
        } else if (!is_letter || value == 'I') {
            return -1;
        }
        text[i] = static_cast<std::uint8_t>(value);
    }

    std::size_t starts[max_text_length], lengths[max_text_length], counts[max_text_length];
    std::size_t unique_count = 0, start = 0;
    while (start < text_length) {
        std::size_t end = start;
        while (end < text_length && text[end] != ' ') ++end;
        const auto word_length = end - start;
        if (word_length > 6) return -1;
        auto found = unique_count;
        for (std::size_t key = 0; key < unique_count; ++key) {
            if (lengths[key] != word_length) continue;
            std::size_t offset = 0;
            while (offset < word_length &&
                   lower_ascii(text[starts[key] + offset]) == lower_ascii(text[start + offset])) ++offset;
            if (offset == word_length) { found = key; break; }
        }
        if (found == unique_count) {
            starts[unique_count] = start;
            lengths[unique_count] = word_length;
            counts[unique_count] = 1;
            ++unique_count;
        } else {
            ++counts[found];
        }
        start = end + 1;
    }

    std::size_t winner = 0;
    for (std::size_t key = 1; key < unique_count; ++key)
        if (counts[key] > counts[winner]) winner = key;
    const auto result_length = lengths[winner];
    if (output_capacity < result_length || output == nullptr) return -2;
    const bool single_word = unique_count == 1 && counts[0] == 1;
    for (std::size_t i = 0; i < result_length; ++i) {
        const auto value = text[starts[winner] + i];
        output[i] = single_word ? value : lower_ascii(value);
    }
    return static_cast<std::int64_t>(result_length);
}
