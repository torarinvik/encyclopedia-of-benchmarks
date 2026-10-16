#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_width = 64;
constexpr std::size_t max_text_bytes = 512;
constexpr std::size_t max_words = 64;
constexpr std::size_t max_input_length = 2 + max_text_bytes + 1;
constexpr std::size_t max_output_bytes = max_words * max_width + max_words;
}

extern "C" std::int64_t text_justification(const std::int64_t *input,
                                             std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto width_value = input[0];
    const auto text_length_value = input[1];
    if (width_value < 1 || width_value > static_cast<std::int64_t>(max_width) ||
        text_length_value < 0 || text_length_value > static_cast<std::int64_t>(max_text_bytes) ||
        length != 2 + static_cast<std::size_t>(text_length_value)) return -1;
    const auto width = static_cast<std::size_t>(width_value);
    const auto text_length = static_cast<std::size_t>(text_length_value);

    std::uint8_t text[max_text_bytes];
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto value = input[index + 2];
        if (value != 32 && (value < 33 || value > 126)) return -1;
        text[index] = static_cast<std::uint8_t>(value);
    }

    std::size_t starts[max_words], lengths[max_words];
    std::size_t word_count = 0;
    for (std::size_t index = 0; index < text_length;) {
        while (index < text_length && text[index] == ' ') ++index;
        if (index == text_length) break;
        const auto start = index;
        while (index < text_length && text[index] != ' ') ++index;
        const auto word_length = index - start;
        if (word_count == max_words || word_length > width) return -1;
        starts[word_count] = start;
        lengths[word_count] = word_length;
        ++word_count;
    }

    std::uint8_t result[max_output_bytes];
    std::size_t result_length = 0, line_start = 0, line_end = 0, letters = 0;
    bool first_line = true;
    for (std::size_t word = 0; word < word_count; ++word) {
        if (letters + lengths[word] + (line_end - line_start) <= width) {
            letters += lengths[word];
            ++line_end;
            continue;
        }
        if (!first_line) result[result_length++] = '\n';
        first_line = false;
        const auto count = line_end - line_start;
        if (count == 1) {
            for (std::size_t i = 0; i < lengths[line_start]; ++i)
                result[result_length++] = text[starts[line_start] + i];
            for (std::size_t i = lengths[line_start]; i < width; ++i)
                result[result_length++] = ' ';
        } else {
            const auto gaps = count - 1;
            const auto spaces = width - letters;
            const auto base = spaces / gaps;
            const auto extra = spaces % gaps;
            for (std::size_t item = 0; item < count; ++item) {
                const auto current = line_start + item;
                for (std::size_t i = 0; i < lengths[current]; ++i)
                    result[result_length++] = text[starts[current] + i];
                if (item + 1 < count) {
                    const auto gap_spaces = base + (item < extra ? 1 : 0);
                    for (std::size_t i = 0; i < gap_spaces; ++i)
                        result[result_length++] = ' ';
                }
            }
        }
        line_start = word;
        line_end = word + 1;
        letters = lengths[word];
    }

    if (!first_line) result[result_length++] = '\n';
    for (std::size_t item = line_start; item < line_end; ++item) {
        if (item != line_start) result[result_length++] = ' ';
        for (std::size_t i = 0; i < lengths[item]; ++i)
            result[result_length++] = text[starts[item] + i];
    }
    const auto trailing_spaces = width - letters - (line_end - line_start) + 1;
    for (std::size_t i = 0; i < trailing_spaces; ++i) result[result_length++] = ' ';

    if (output_capacity < result_length || (result_length != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < result_length; ++index) output[index] = result[index];
    return static_cast<std::int64_t>(result_length);
}
