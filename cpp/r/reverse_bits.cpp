/* Reverse the bit order of an unsigned 32-bit word. */
#include <cstdint>

extern "C" std::int64_t reverse_bits(std::int64_t value) noexcept {
    if (value < 0 || static_cast<std::uint64_t>(value) > UINT32_MAX) return -1;
    std::uint32_t remaining = static_cast<std::uint32_t>(value);
    std::uint32_t reversed = 0;
    for (unsigned bit = 0; bit < 32; ++bit) {
        reversed = (reversed << 1) | (remaining & std::uint32_t{1});
        remaining >>= 1;
    }
    return static_cast<std::int64_t>(reversed);
}
