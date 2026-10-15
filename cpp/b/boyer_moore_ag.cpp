/* All-match Boyer-Moore search with Apostolico-Giancarlo suffix memory. */
#include <cstddef>
#include <cstdint>

namespace {
std::size_t collect_matches(const std::int64_t *values, std::size_t text_length,
                            std::size_t pattern_length, std::size_t pattern_start,
                            std::uint8_t positions[255]) noexcept
{
    std::size_t bad_shift[128]{};
    bool present[128]{};
    std::size_t suffix_skip[256]{};
    for (std::size_t index = 0; index + 1 < pattern_length; ++index) {
        const auto byte = static_cast<std::size_t>(values[pattern_start + index]);
        bad_shift[byte] = pattern_length - index - 1;
        present[byte] = true;
    }
    for (std::size_t byte = 0; byte < 128; ++byte) {
        if (!present[byte]) continue;
        const auto shift = bad_shift[byte];
        std::size_t matched = 0;
        while (matched < pattern_length - shift &&
               values[pattern_start + pattern_length - 1 - matched] ==
                   values[pattern_start + pattern_length - 1 - shift - matched]) ++matched;
        suffix_skip[shift] = matched;
    }

    std::size_t count = 0, start = 0, jump = pattern_length;
    while (start <= text_length - pattern_length) {
        const auto skip = suffix_skip[jump];
        int index = static_cast<int>(pattern_length) - 1;
        while (index >= 0) {
            if (values[2 + start + static_cast<std::size_t>(index)] !=
                values[pattern_start + static_cast<std::size_t>(index)]) {
                const auto mismatch = static_cast<std::size_t>(values[2 + start + static_cast<std::size_t>(index)]);
                jump = present[mismatch] ? bad_shift[mismatch] : pattern_length;
                start += jump;
                break;
            }
            if (static_cast<std::size_t>(index) == pattern_length - jump) index -= static_cast<int>(skip);
            if (index == 0) {
                positions[count++] = static_cast<std::uint8_t>(start);
                jump = 1;
                ++start;
                break;
            }
            --index;
        }
    }
    return count;
}
}

extern "C" std::int64_t boyer_moore_ag(const std::int64_t *values, std::size_t length,
                                        std::uint8_t *output,
                                        std::size_t output_capacity) noexcept
{
    if (values == nullptr || length < 2 || length > 512) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 1 || values[1] > 255) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    const auto pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;

    std::uint8_t positions[255]{};
    const auto count = pattern_length > text_length ? 0 :
        collect_matches(values, text_length, pattern_length, 2 + text_length, positions);
    if (output_capacity < count || (count != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < count; ++index) output[index] = positions[index];
    return static_cast<std::int64_t>(count);
}
