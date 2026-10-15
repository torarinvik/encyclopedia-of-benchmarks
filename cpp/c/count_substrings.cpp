#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

static std::int64_t find_next(const std::int64_t* values, std::size_t text_length,
                              std::size_t pattern_length, std::size_t pattern_start,
                              std::size_t start) {
    if (start > text_length || pattern_length > text_length - start) return -1;
    const std::size_t last = text_length - pattern_length;
    for (std::size_t position = start; position <= last; ++position) {
        std::size_t offset = 0;
        while (offset < pattern_length && values[2 + position + offset] == values[pattern_start + offset]) ++offset;
        if (offset == pattern_length) return static_cast<std::int64_t>(position);
    }
    return -1;
}

extern "C" std::int64_t count_substrings(const std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || values[0] < 0 || values[0] > max_length || values[1] < 0 || values[1] > max_length) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    const std::size_t pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t i = 2; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    if (pattern_length == 0) return static_cast<std::int64_t>(text_length) + 1;
    const std::size_t pattern_start = 2 + text_length;
    std::int64_t count = 0;
    std::int64_t position = find_next(values, text_length, pattern_length, pattern_start, 0);
    while (position >= 0) {
        ++count;
        position = find_next(values, text_length, pattern_length, pattern_start, static_cast<std::size_t>(position) + 1);
    }
    return count;
}
