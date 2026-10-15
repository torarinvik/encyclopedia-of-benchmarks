/* Return the first ASCII byte match using bad-character and good-suffix shifts. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaximumPatternLength = 4096;
constexpr std::size_t kAlphabetSize = 127;
}

extern "C" std::int64_t boyer_moore(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 2 + 2 * kMaximumPatternLength) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(kMaximumPatternLength) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(kMaximumPatternLength)) return -1;
    const auto text_length = static_cast<std::size_t>(values[0]);
    const auto pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -1;
    for (std::size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] >= static_cast<std::int64_t>(kAlphabetSize)) return -1;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const std::size_t pattern_start = 2 + text_length;
    std::int64_t last_occurrence[kAlphabetSize];
    for (std::size_t byte = 0; byte < kAlphabetSize; ++byte) last_occurrence[byte] = -1;
    for (std::size_t index = 0; index < pattern_length; ++index)
        last_occurrence[static_cast<std::size_t>(values[pattern_start + index])] = static_cast<std::int64_t>(index);

    std::size_t good_suffix[kMaximumPatternLength + 1] = {};
    std::size_t border_position[kMaximumPatternLength + 1] = {};
    std::size_t i = pattern_length;
    std::size_t j = pattern_length + 1;
    border_position[i] = j;
    while (i > 0) {
        while (j <= pattern_length && values[pattern_start + i - 1] != values[pattern_start + j - 1]) {
            if (good_suffix[j] == 0) good_suffix[j] = j - i;
            j = border_position[j];
        }
        --i;
        --j;
        border_position[i] = j;
    }
    j = border_position[0];
    for (i = 0; i <= pattern_length; ++i) {
        if (good_suffix[i] == 0) good_suffix[i] = j;
        if (i == j) j = border_position[j];
    }

    std::size_t alignment = 0;
    while (alignment <= text_length - pattern_length) {
        std::size_t pattern_index = pattern_length;
        while (pattern_index > 0 &&
               values[pattern_start + pattern_index - 1] == values[2 + alignment + pattern_index - 1])
            --pattern_index;
        if (pattern_index == 0) return static_cast<std::int64_t>(alignment);

        const auto text_byte = static_cast<std::size_t>(values[2 + alignment + pattern_index - 1]);
        auto bad_shift = static_cast<std::int64_t>(pattern_index - 1) - last_occurrence[text_byte];
        if (bad_shift < 1) bad_shift = 1;
        const auto shift = good_suffix[pattern_index] > static_cast<std::size_t>(bad_shift)
            ? good_suffix[pattern_index] : static_cast<std::size_t>(bad_shift);
        alignment += shift;
    }
    return -1;
}
