#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t min_values(const std::int64_t *values, std::size_t length) noexcept {
    constexpr auto invalid = std::numeric_limits<std::int64_t>::min();
    if (values == nullptr || length < 1 || length > 257) return invalid;
    const auto count = values[0];
    if (count < 1 || count > 256 || length != static_cast<std::size_t>(count) + 1) return invalid;
    auto result = values[1];
    if (result < std::numeric_limits<std::int32_t>::min() || result > std::numeric_limits<std::int32_t>::max()) return invalid;
    for (std::size_t index = 2; index < length; ++index) {
        const auto value = values[index];
        if (value < std::numeric_limits<std::int32_t>::min() || value > std::numeric_limits<std::int32_t>::max()) return invalid;
        if (value < result) result = value;
    }
    return result;
}
