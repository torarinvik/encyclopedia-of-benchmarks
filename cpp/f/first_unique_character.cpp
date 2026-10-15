// Return the first lowercase ASCII letter whose frequency is one.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 1024;
constexpr std::int64_t invalid_result = -2;
}

extern "C" std::int64_t first_unique_character(const std::int64_t *values,
                                                std::size_t length) noexcept {
    if (length > max_length || (length != 0 && values == nullptr)) return invalid_result;
    std::size_t counts[26]{};
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < 'a' || values[i] > 'z') return invalid_result;
        ++counts[static_cast<std::size_t>(values[i] - 'a')];
    }
    for (std::size_t i = 0; i < length; ++i)
        if (counts[static_cast<std::size_t>(values[i] - 'a')] == 1) return static_cast<std::int64_t>(i);
    return -1;
}
