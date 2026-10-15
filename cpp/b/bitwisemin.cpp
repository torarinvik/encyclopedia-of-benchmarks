// Reduce the input array to its minimum with a sign-bit mask.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 4096;
constexpr std::int64_t max_value = 2'147'483'647;
}

extern "C" std::int64_t bitwisemin(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_length) return -1;
    std::int64_t minimum = values[0];
    if (minimum < 0 || minimum > max_value) return -1;
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t value = values[index];
        if (value < 0 || value > max_value) return -1;
        const std::int64_t difference = minimum - value;
        const std::uint32_t keep_minimum = 0U - ((static_cast<std::uint32_t>(difference) >> 31) & 1U);
        minimum = static_cast<std::int64_t>((static_cast<std::uint32_t>(minimum) & keep_minimum) |
                                            (static_cast<std::uint32_t>(value) & ~keep_minimum));
    }
    return minimum;
}
