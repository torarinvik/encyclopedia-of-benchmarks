#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_text_length = 4096;
constexpr std::int64_t max_pattern_length = 63;
}

extern "C" std::int64_t bitap_string_match(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 2 || values[0] < 0 || values[0] > max_text_length ||
        values[1] < 0 || values[1] > max_pattern_length) return -2;
    const auto text_length = static_cast<std::size_t>(values[0]);
    const auto pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -2;
    for (std::size_t index = 2; index < length; ++index)
        if (values[index] < 'a' || values[index] > 'z') return -2;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    std::array<std::uint64_t, 26> masks;
    masks.fill(UINT64_MAX);
    for (std::size_t index = 0; index < pattern_length; ++index) {
        const auto letter = static_cast<std::size_t>(values[2 + text_length + index] - 'a');
        masks[letter] &= ~(UINT64_C(1) << index);
    }
    std::uint64_t state = ~UINT64_C(1);
    for (std::size_t index = 0; index < text_length; ++index) {
        const auto letter = static_cast<std::size_t>(values[2 + index] - 'a');
        state |= masks[letter];
        state <<= 1;
        if ((state & (UINT64_C(1) << pattern_length)) == 0)
            return static_cast<std::int64_t>(index) - static_cast<std::int64_t>(pattern_length) + 1;
    }
    return -1;
}
