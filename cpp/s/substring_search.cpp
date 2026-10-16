#include <cstddef>
#include <cstdint>

extern "C" std::int64_t substring_search(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 2 || length > 195) return -2;
    const auto text_length = values[0], pattern_length = values[1];
    if (text_length < 0 || text_length > 128 || pattern_length < 0 || pattern_length > 64 ||
        length != 2 + static_cast<std::size_t>(text_length + pattern_length)) return -2;
    const std::size_t text_start = 2, pattern_start = text_start + static_cast<std::size_t>(text_length);
    for (std::size_t i = text_start; i < length; ++i) if (values[i] < 1 || values[i] > 127) return -2;
    std::size_t text_index = 0, pattern_index = 0;
    std::int64_t match_start = -1;
    while (text_index < static_cast<std::size_t>(text_length)) {
        const std::int64_t expected = pattern_index < static_cast<std::size_t>(pattern_length)
            ? values[pattern_start + pattern_index] : 0;
        if (values[text_start + text_index] == expected) {
            if (match_start == -1) match_start = static_cast<std::int64_t>(text_index);
            ++pattern_index;
            if (pattern_index == static_cast<std::size_t>(pattern_length)) return match_start;
            ++text_index;
        } else {
            match_start = -1;
            pattern_index = 0;
            ++text_index;
        }
    }
    return -1;
}
