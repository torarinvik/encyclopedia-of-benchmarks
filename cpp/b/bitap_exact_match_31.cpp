#include <array>
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t max_text = 4096, max_pattern = 31; }

extern "C" std::int64_t bitap_exact_match_31(const std::int64_t *values, std::size_t length) noexcept {
    if (!values || length < 2 || values[0] < 0 || values[0] > max_text || values[1] < 0 || values[1] > max_pattern) return -2;
    const auto text_length = static_cast<std::size_t>(values[0]);
    const auto pattern_length = static_cast<std::size_t>(values[1]);
    if (length != 2 + text_length + pattern_length) return -2;
    for (std::size_t i = 2; i < length; ++i) if (values[i] < 'a' || values[i] > 'z') return -2;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;
    std::array<std::uint32_t, 26> masks;
    masks.fill(UINT32_MAX);
    for (std::size_t i = 0; i < pattern_length; ++i) masks[static_cast<std::size_t>(values[2 + text_length + i] - 'a')] &= ~(UINT32_C(1) << i);
    std::uint32_t state = ~UINT32_C(1);
    for (std::size_t i = 0; i < text_length; ++i) {
        state |= masks[static_cast<std::size_t>(values[2 + i] - 'a')];
        state <<= 1;
        if ((state & (UINT32_C(1) << pattern_length)) == 0) return static_cast<std::int64_t>(i) - static_cast<std::int64_t>(pattern_length) + 1;
    }
    return -1;
}
