// Exchange each adjacent pair of low 30 bits.
#include <cstdint>

extern "C" std::int64_t swap_adjacent_bits(std::int64_t input) noexcept {
    if (input < 0 || input > 1'073'741'823) return -1;
    const auto value = static_cast<std::uint32_t>(input);
    return static_cast<std::int64_t>(((value & UINT32_C(0xAAAAAAAA)) >> 1)
        | ((value & UINT32_C(0x55555555)) << 1));
}
