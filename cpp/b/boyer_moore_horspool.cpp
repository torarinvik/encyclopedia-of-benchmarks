/* Find every ASCII byte match with the Boyer-Moore-Horspool shift rule. */
#include <cstddef>
#include <cstdint>

namespace {
std::size_t count_matches(const std::int64_t *values, std::size_t text_length,
                          std::size_t pattern_length, std::size_t pattern_start,
                          const std::size_t shifts[128]) noexcept
{
    if (pattern_length == 0) return text_length + 1;
    if (pattern_length > text_length) return 0;
    std::size_t count = 0, start = 0;
    while (start <= text_length - pattern_length) {
        std::size_t current = pattern_length;
        while (current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1]) --current;
        if (current == 0) { ++count; ++start; }
        else start += shifts[static_cast<std::size_t>(values[2 + start + pattern_length - 1])];
    }
    return count;
}
}

extern "C" std::int64_t boyer_moore_horspool(const std::int64_t *values, std::size_t length,
                                              std::uint8_t *output,
                                              std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 512) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    const std::size_t pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    const std::size_t pattern_start = 2 + text_length;
    for (std::size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;

    std::size_t shifts[128];
    for (auto &shift : shifts) shift = pattern_length;
    for (std::size_t index = 0; index + 1 < pattern_length; ++index)
        shifts[static_cast<std::size_t>(values[pattern_start + index])] = pattern_length - 1 - index;
    const std::size_t match_count = count_matches(values, text_length, pattern_length, pattern_start, shifts);
    if (output_capacity < match_count || (match_count != 0 && output == nullptr)) return -2;

    std::size_t written = 0;
    if (pattern_length == 0) {
        for (std::size_t position = 0; position <= text_length; ++position)
            output[written++] = static_cast<std::uint8_t>(position);
    } else if (pattern_length <= text_length) {
        std::size_t start = 0;
        while (start <= text_length - pattern_length) {
            std::size_t current = pattern_length;
            while (current > 0 && values[pattern_start + current - 1] == values[2 + start + current - 1]) --current;
            if (current == 0) { output[written++] = static_cast<std::uint8_t>(start); ++start; }
            else start += shifts[static_cast<std::size_t>(values[2 + start + pattern_length - 1])];
        }
    }
    return static_cast<std::int64_t>(written);
}
