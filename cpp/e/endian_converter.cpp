/* Reverse the byte order of a signed 32-bit integer. */
#include <cstdint>
extern "C" std::int64_t endian_converter(std::int64_t value) noexcept {
    if (value < INT32_MIN || value > INT32_MAX) return -2147483649LL;
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    const auto reversed = ((bits & 0x000000ffU) << 24) | ((bits & 0x0000ff00U) << 8) |
                          ((bits & 0x00ff0000U) >> 8) | ((bits & 0xff000000U) >> 24);
    return reversed <= 0x7fffffffU ? static_cast<std::int64_t>(reversed)
                                  : static_cast<std::int64_t>(reversed) - 4294967296LL;
}
