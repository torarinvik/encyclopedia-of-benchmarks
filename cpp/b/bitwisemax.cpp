// Select the larger signed-32-bit nonnegative value with a sign bit.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t max_value = 2'147'483'647; }

extern "C" std::int64_t bitwisemax(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t left = values[0];
    const std::int64_t right = values[1];
    if (left < 0 || left > max_value || right < 0 || right > max_value) return -1;
    const std::int64_t difference = left - right;
    const std::uint32_t choose_right = (static_cast<std::uint32_t>(difference) >> 31) & 1U;
    return left - static_cast<std::int64_t>(choose_right) * difference;
}
