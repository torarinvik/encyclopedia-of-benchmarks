#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 512;
constexpr std::size_t max_input_length = max_text_length + 3;
constexpr std::size_t max_output_bytes = 2 * max_text_length + 8;

bool is_stripped_punctuation(std::uint8_t value) noexcept
{
    return value == '.' || value == ',' || value == '!' || value == '?' || value == '(' ||
           value == ')' || value == '[' || value == ']' || value == '{' || value == '}';
}

void put_u32(std::uint8_t *output, std::size_t offset, std::uint32_t value) noexcept
{
    output[offset] = static_cast<std::uint8_t>(value);
    output[offset + 1] = static_cast<std::uint8_t>(value >> 8);
    output[offset + 2] = static_cast<std::uint8_t>(value >> 16);
    output[offset + 3] = static_cast<std::uint8_t>(value >> 24);
}
}

extern "C" std::int64_t largest_smallest_words(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto text_length_value = input[0];
    if (text_length_value < 1 || text_length_value > static_cast<std::int64_t>(max_text_length) ||
        length != 1 + static_cast<std::size_t>(text_length_value)) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    std::uint8_t text[max_text_length];
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[i + 1];
        if (value < 32 || value > 126) return -1;
        text[i] = static_cast<std::uint8_t>(value);
    }

    std::size_t smallest_start = 0, largest_start = 0;
    std::size_t smallest_length = max_text_length + 1, largest_length = 0, word_count = 0;
    for (std::size_t pos = 0; pos < text_length;) {
        while (pos < text_length && text[pos] == ' ') ++pos;
        if (pos == text_length) break;
        const auto token_start = pos;
        while (pos < text_length && text[pos] != ' ') ++pos;
        auto start = token_start;
        auto end = pos;
        while (start < end && is_stripped_punctuation(text[start])) ++start;
        while (end > start && is_stripped_punctuation(text[end - 1])) --end;
        const auto word_length = end - start;
        if (word_length < smallest_length) { smallest_start = start; smallest_length = word_length; }
        if (word_length > largest_length) { largest_start = start; largest_length = word_length; }
        ++word_count;
    }
    if (word_count == 0) return -1;
    const auto output_length = 8 + smallest_length + largest_length;
    if (output_capacity < output_length || output == nullptr) return -2;
    put_u32(output, 0, static_cast<std::uint32_t>(smallest_length));
    for (std::size_t i = 0; i < smallest_length; ++i) output[4 + i] = text[smallest_start + i];
    const auto largest_header = 4 + smallest_length;
    put_u32(output, largest_header, static_cast<std::uint32_t>(largest_length));
    for (std::size_t i = 0; i < largest_length; ++i)
        output[largest_header + 4 + i] = text[largest_start + i];
    return static_cast<std::int64_t>(output_length);
}
