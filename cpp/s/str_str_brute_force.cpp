// Return the first pattern occurrence using a direct character-by-character scan.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_string_length = 1024; }

extern "C" std::int64_t str_str_brute_force(const std::int64_t *packed,
    std::size_t length) noexcept {
    if (packed == nullptr || length < 2 || length > 2 + 2 * max_string_length) return -1;
    if (packed[0] < 0 || packed[0] > static_cast<std::int64_t>(max_string_length) ||
        packed[1] < 0 || packed[1] > static_cast<std::int64_t>(max_string_length)) return -1;
    const auto text_length = static_cast<std::size_t>(packed[0]);
    const auto pattern_length = static_cast<std::size_t>(packed[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t index = 0; index < text_length + pattern_length; ++index)
        if (packed[2 + index] < 1 || packed[2 + index] > 127) return -1;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const auto pattern_start = 2 + text_length;
    for (std::size_t start = 0; start <= text_length - pattern_length; ++start) {
        std::size_t offset = 0;
        while (offset < pattern_length &&
               packed[2 + start + offset] == packed[pattern_start + offset]) ++offset;
        if (offset == pattern_length) return static_cast<std::int64_t>(start);
    }
    return -1;
}
