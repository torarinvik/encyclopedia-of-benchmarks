#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_PATTERN_LENGTH = 8;
constexpr std::size_t MAX_TEXT_LENGTH = 32;
constexpr std::size_t MAX_INPUT_LENGTH = 43;

bool match_word_pattern_search(const std::int64_t *pattern, std::size_t pattern_length,
                               const std::int64_t *text, std::size_t text_length,
                               std::size_t pattern_index, std::size_t text_index,
                               std::size_t *mapped_start, std::size_t *mapped_length)
{
    if (pattern_index == pattern_length) return text_index == text_length;
    if (text_index == text_length) return false;

    const std::size_t symbol = static_cast<std::size_t>(pattern[pattern_index]);
    const std::size_t known_length = mapped_length[symbol];
    if (known_length != 0) {
        if (known_length > text_length - text_index) return false;
        for (std::size_t offset = 0; offset < known_length; ++offset) {
            if (text[mapped_start[symbol] + offset] != text[text_index + offset]) return false;
        }
        return match_word_pattern_search(pattern, pattern_length, text, text_length,
                                         pattern_index + 1, text_index + known_length,
                                         mapped_start, mapped_length);
    }

    for (std::size_t end = text_index + 1; end <= text_length; ++end) {
        const std::size_t candidate_length = end - text_index;
        bool already_used = false;
        for (std::size_t other_index = 0; other_index < pattern_index; ++other_index) {
            const std::size_t other = static_cast<std::size_t>(pattern[other_index]);
            if (other == symbol) continue;
            if (mapped_length[other] != candidate_length) continue;
            bool equal = true;
            for (std::size_t offset = 0; offset < candidate_length; ++offset) {
                if (text[mapped_start[other] + offset] != text[text_index + offset]) {
                    equal = false;
                    break;
                }
            }
            if (equal) {
                already_used = true;
                break;
            }
        }
        if (already_used) continue;

        mapped_start[symbol] = text_index;
        mapped_length[symbol] = candidate_length;
        if (match_word_pattern_search(pattern, pattern_length, text, text_length,
                                      pattern_index + 1, end, mapped_start, mapped_length)) {
            return true;
        }
        mapped_length[symbol] = 0;
    }
    return false;
}
}

extern "C" std::int64_t match_word_pattern(const std::int64_t *input,
                                             std::size_t input_length) noexcept
{
    if (input == nullptr || input_length < 2 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_PATTERN_LENGTH)
        || input[1] < 0 || input[1] > static_cast<std::int64_t>(MAX_TEXT_LENGTH)) return -1;
    const std::size_t pattern_length = static_cast<std::size_t>(input[0]);
    const std::size_t text_length = static_cast<std::size_t>(input[1]);
    if (input_length != 2 + pattern_length + text_length) return -1;
    for (std::size_t index = 0; index < pattern_length + text_length; ++index) {
        if (input[2 + index] < 0 || input[2 + index] > 127) return -1;
    }

    std::size_t mapped_start[128]{};
    std::size_t mapped_length[128]{};
    return match_word_pattern_search(input + 2, pattern_length,
                                     input + 2 + pattern_length, text_length,
                                     0, 0, mapped_start, mapped_length) ? 1 : 0;
}
