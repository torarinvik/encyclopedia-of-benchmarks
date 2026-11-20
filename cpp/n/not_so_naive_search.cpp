#include <cstddef>
#include <cstdint>

enum { MAX_TEXT = 512, MIN_PATTERN = 2, MAX_PATTERN = 64, MAX_INPUT = 578 };

extern "C" std::int64_t not_so_naive_search(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || length > MAX_INPUT) return -2;
    const std::int64_t text_length_value = values[0];
    const std::int64_t pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > MAX_TEXT ||
        pattern_length_value < MIN_PATTERN || pattern_length_value > MAX_PATTERN) return -2;
    const std::size_t text_length = static_cast<std::size_t>(text_length_value);
    const std::size_t pattern_length = static_cast<std::size_t>(pattern_length_value);
    if (length != 2 + text_length + pattern_length) return -2;
    const std::size_t pattern_start = 2 + text_length;
    for (std::size_t i = 0; i < text_length + pattern_length; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 127) return -2;
    if (pattern_length > text_length) return -1;

    const bool same_prefix = values[pattern_start] == values[pattern_start + 1];
    const std::size_t mismatch_shift = same_prefix ? 2 : 1;
    const std::size_t post_check_shift = same_prefix ? 1 : 2;
    std::size_t position = 0;
    const std::size_t last_start = text_length - pattern_length;
    while (position <= last_start) {
        if (values[pattern_start + 1] != values[2 + position + 1]) {
            position += mismatch_shift;
            continue;
        }
        std::size_t pattern_index = 2;
        while (pattern_index < pattern_length &&
               values[pattern_start + pattern_index] == values[2 + position + pattern_index])
            ++pattern_index;
        if (pattern_index == pattern_length && values[pattern_start] == values[2 + position])
            return static_cast<std::int64_t>(position);
        position += post_check_shift;
    }
    return -1;
}
