#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_pattern_length = 63;
constexpr std::int64_t max_text_length = 4096;
constexpr std::int64_t max_errors = 2;
}

extern "C" std::int64_t agrep_approx_substring_count(const std::int64_t *values,
                                                       std::size_t length) {
    if (values == nullptr || length < 3 || values[0] < 1 || values[0] > max_pattern_length ||
        values[1] < 0 || values[1] > max_text_length || values[2] < 0 || values[2] > max_errors)
        return -2;
    const auto pattern_length = static_cast<std::size_t>(values[0]);
    const auto text_length = static_cast<std::size_t>(values[1]);
    if (length != 3 + pattern_length + text_length) return -2;
    for (std::size_t i = 3; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -2;

    std::array<std::int64_t, 64> previous{};
    std::array<std::int64_t, 64> current{};
    for (std::size_t j = 0; j <= pattern_length; ++j) previous[j] = static_cast<std::int64_t>(j);
    std::int64_t matches = 0;
    const std::size_t text_offset = 3 + pattern_length;
    for (std::size_t i = 0; i < text_length; ++i) {
        current[0] = 0;
        for (std::size_t j = 1; j <= pattern_length; ++j) {
            const std::int64_t substitution = previous[j - 1] +
                (values[3 + j - 1] == values[text_offset + i] ? 0 : 1);
            current[j] = std::min({previous[j] + 1, current[j - 1] + 1, substitution});
        }
        if (current[pattern_length] <= values[2]) ++matches;
        std::copy_n(current.begin(), pattern_length + 1, previous.begin());
    }
    return matches;
}
