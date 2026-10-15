/* Find every occurrence of a byte pattern with a direct window scan. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t naive_search(const std::int64_t *values, std::size_t length,
                                     std::uint8_t *output,
                                     std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 512) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    const std::size_t pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    const std::size_t pattern_start = 2 + text_length;
    for (std::size_t index = 0; index < text_length; ++index)
        if (values[2 + index] < 1 || values[2 + index] > 127) return -1;
    for (std::size_t index = 0; index < pattern_length; ++index)
        if (values[pattern_start + index] < 1 || values[pattern_start + index] > 127) return -1;

    std::size_t match_count = 0;
    if (pattern_length <= text_length) {
        for (std::size_t start = 0; start <= text_length - pattern_length; ++start) {
            std::size_t offset = 0;
            while (offset < pattern_length &&
                   values[2 + start + offset] == values[pattern_start + offset]) ++offset;
            if (offset == pattern_length) ++match_count;
        }
    }
    if (output_capacity < match_count || (match_count != 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    if (pattern_length <= text_length) {
        for (std::size_t start = 0; start <= text_length - pattern_length; ++start) {
            std::size_t offset = 0;
            while (offset < pattern_length &&
                   values[2 + start + offset] == values[pattern_start + offset]) ++offset;
            if (offset == pattern_length) output[written++] = static_cast<std::uint8_t>(start);
        }
    }
    return static_cast<std::int64_t>(written);
}
