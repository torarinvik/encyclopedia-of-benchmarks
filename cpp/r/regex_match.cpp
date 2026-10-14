// Direct recursive full-string matching for the . and * regular-expression subset.
#include <cstddef>
#include <cstdint>

static bool regex_match_recursive(const int64_t *values, std::size_t text_length,
                                  std::size_t pattern_start, std::size_t pattern_length,
                                  std::size_t text_index, std::size_t pattern_index)
{
    if (pattern_index == pattern_length) return text_index == text_length;
    const int64_t atom = values[pattern_start + pattern_index];
    if (pattern_index + 1 < pattern_length && values[pattern_start + pattern_index + 1] == '*') {
        if (regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                  text_index, pattern_index + 2)) return true;
        return text_index < text_length && (atom == '.' || atom == values[2 + text_index])
            && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                     text_index + 1, pattern_index);
    }
    return text_index < text_length && (atom == '.' || atom == values[2 + text_index])
        && regex_match_recursive(values, text_length, pattern_start, pattern_length,
                                 text_index + 1, pattern_index + 1);
}

extern "C" int64_t regex_match(const int64_t *values, std::size_t length)
{
    if (length < 2) return -1;
    if (values[0] < 0 || values[0] > 12 || values[1] < 0 || values[1] > 20) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    const std::size_t pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    const std::size_t pattern_start = 2 + text_length;
    for (std::size_t index = 0; index < text_length; ++index) {
        if (values[2 + index] < 'a' || values[2 + index] > 'z') return -1;
    }
    for (std::size_t index = 0; index < pattern_length; ++index) {
        const int64_t symbol = values[pattern_start + index];
        if (!((symbol >= 'a' && symbol <= 'z') || symbol == '.' || symbol == '*')) return -1;
        if (symbol == '*' && (index == 0 || values[pattern_start + index - 1] == '*')) return -1;
    }
    return regex_match_recursive(values, text_length, pattern_start, pattern_length, 0, 0);
}
