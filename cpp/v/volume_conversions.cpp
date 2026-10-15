#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
double unit_factor_to_cubic_meters(std::int64_t unit) noexcept
{
    return unit == 1 ? 0.001 : 1.0;
}
}

extern "C" std::int64_t volume_conversions(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length != 3) return -1;
    const std::int64_t value = input[0], from_unit = input[1], to_unit = input[2];
    if (value < 0 || value > 1000 || from_unit < 0 || from_unit > 2 ||
        to_unit < 0 || to_unit > 2 || from_unit == to_unit) return -1;
    if (capacity < 8 || output == nullptr) return -2;
    const double cubic_meters = static_cast<double>(value) * unit_factor_to_cubic_meters(from_unit);
    const double converted = cubic_meters / unit_factor_to_cubic_meters(to_unit);
    std::uint64_t bits;
    std::memcpy(&bits, &converted, sizeof(bits));
    for (std::size_t byte = 0; byte < 8; ++byte) output[byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    return 8;
}
