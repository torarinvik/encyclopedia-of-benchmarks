#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_length = 256;
constexpr std::size_t max_parseable_input_length = max_text_length + 2;
bool is_trim_byte(std::int64_t value) noexcept { return value >= 0 && value <= 32; }
bool is_split_space(std::int64_t value) noexcept { return value == 32 || (value >= 9 && value <= 13); }
}

extern "C" std::int64_t reverse_words_in_string(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length == 0 || length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_length)
        || length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto text_length = static_cast<std::size_t>(input[0]);
    for (std::size_t i = 0; i < text_length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;

    std::size_t start = 0, end = text_length;
    while (start < end && is_trim_byte(input[start + 1])) ++start;
    while (end > start && is_trim_byte(input[end])) --end;

    std::size_t output_length = 0, word_count = 0, position = start;
    while (position < end) {
        while (position < end && is_split_space(input[position + 1])) ++position;
        if (position == end) break;
        const std::size_t token_start = position;
        while (position < end && !is_split_space(input[position + 1])) ++position;
        output_length += position - token_start;
        if (word_count > 0) ++output_length;
        ++word_count;
    }
    if (capacity < output_length || (output_length > 0 && output == nullptr)) return -2;

    std::size_t written = 0, emitted = 0;
    position = end;
    while (position > start) {
        while (position > start && is_split_space(input[position])) --position;
        if (position == start) break;
        const std::size_t token_end = position;
        while (position > start && !is_split_space(input[position])) --position;
        const std::size_t token_start = position;
        if (emitted > 0) output[written++] = ' ';
        for (std::size_t i = token_start; i < token_end; ++i)
            output[written++] = static_cast<std::uint8_t>(input[i + 1]);
        ++emitted;
    }
    return static_cast<std::int64_t>(written);
}
