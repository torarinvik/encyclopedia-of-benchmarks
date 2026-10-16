// Reverse the eight bytes in a 64-bit bit pattern.
#include <cstdint>

extern "C" std::int64_t byte_encoding_utils(std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    const auto reversed = ((bits & 0x00000000000000ffULL) << 56) |
                          ((bits & 0x000000000000ff00ULL) << 40) |
                          ((bits & 0x0000000000ff0000ULL) << 24) |
                          ((bits & 0x00000000ff000000ULL) << 8) |
                          ((bits & 0x000000ff00000000ULL) >> 8) |
                          ((bits & 0x0000ff0000000000ULL) >> 24) |
                          ((bits & 0x00ff000000000000ULL) >> 40) |
                          ((bits & 0xff00000000000000ULL) >> 56);
    if (reversed <= static_cast<std::uint64_t>(INT64_MAX))
        return static_cast<std::int64_t>(reversed);
    return -1 - static_cast<std::int64_t>(UINT64_MAX - reversed);
}
