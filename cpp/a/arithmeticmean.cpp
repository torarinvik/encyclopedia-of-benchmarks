// Overflow-safe floor arithmetic mean using the bitwise identity.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t max_value = INT64_C(9000000000000000000); }

extern "C" std::int64_t arithmeticmean(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1;
    const std::int64_t left = values[0];
    const std::int64_t right = values[1];
    if (left < 0 || left > max_value || right < 0 || right > max_value) return -1;
    return ((left ^ right) >> 1) + (left & right);
}
