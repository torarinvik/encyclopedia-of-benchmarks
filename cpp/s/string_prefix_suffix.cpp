#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t max_code_units = 1024; }

// mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units.
extern "C" std::int64_t string_prefix_suffix(const std::int64_t *values,
                                                std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > 2052) return -1;
    const auto mode = values[0];
    const auto text_count_value = values[1];
    const auto pattern_count_value = values[2];
    if ((mode != 0 && mode != 1) || text_count_value < 0 || text_count_value > max_code_units ||
        pattern_count_value < 0 || pattern_count_value > max_code_units) return -1;
    const auto text_count = static_cast<std::size_t>(text_count_value);
    const auto pattern_count = static_cast<std::size_t>(pattern_count_value);
    if (length != 3 + text_count + pattern_count) return -1;
    for (std::size_t index = 0; index < text_count + pattern_count; ++index)
        if (values[3 + index] < 0 || values[3 + index] > 65535) return -1;
    if (pattern_count > text_count) return 0;
    const std::size_t start = mode == 0 ? 0 : text_count - pattern_count;
    for (std::size_t index = 0; index < pattern_count; ++index)
        if (values[3 + start + index] != values[3 + text_count + index]) return 0;
    return 1;
}
