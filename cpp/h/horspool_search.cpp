#include <cstddef>
#include <cstdint>

extern "C" std::int64_t horspool_search(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length < 2) return -2;
    const auto text_length_value = packed[0];
    const auto pattern_length_value = packed[1];
    if (text_length_value < 0 || text_length_value > 512 || pattern_length_value < 0
        || pattern_length_value > 64 || length != static_cast<std::size_t>(text_length_value + pattern_length_value) + 2) return -2;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto pattern_length = static_cast<std::size_t>(pattern_length_value);
    const auto pattern_start = 2 + text_length;
    for (std::size_t i = 0; i < text_length; ++i) if (packed[2 + i] < 0 || packed[2 + i] > 127) return -2;
    for (std::size_t i = 0; i < pattern_length; ++i) if (packed[pattern_start + i] < 0 || packed[pattern_start + i] > 127) return -2;
    if (pattern_length == 0 || pattern_length > text_length) return -1;
    std::size_t shifts[128];
    for (std::size_t ch = 0; ch < 128; ++ch) shifts[ch] = pattern_length;
    for (std::size_t i = pattern_length - 1; i > 0; --i) {
        const auto ch = static_cast<std::size_t>(packed[pattern_start + i - 1]);
        if (shifts[ch] == pattern_length) shifts[ch] = pattern_length - i;
    }
    std::size_t end = pattern_length - 1;
    while (end < text_length) {
        std::size_t offset = 0;
        while (offset < pattern_length && packed[pattern_start + pattern_length - 1 - offset] == packed[2 + end - offset]) ++offset;
        if (offset == pattern_length) return static_cast<std::int64_t>(end - pattern_length + 1);
        end += shifts[static_cast<std::size_t>(packed[2 + end])];
    }
    return -1;
}
