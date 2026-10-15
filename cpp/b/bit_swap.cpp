// Swap two 0-based bits in a signed 32-bit value.
#include <cstddef>
#include <cstdint>

static std::int64_t sign_extend_u32(std::uint32_t bits)
{
    return bits <= INT32_MAX ? static_cast<std::int64_t>(bits) : static_cast<std::int64_t>(bits) - INT64_C(4294967296);
}

extern "C" std::int64_t bit_swap(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length != 3) return -INT64_C(2147483649);
    const std::int64_t data = values[0];
    const std::int64_t pos_a = values[1];
    const std::int64_t pos_b = values[2];
    if (data < INT32_MIN || data > INT32_MAX || pos_a < 0 || pos_a >= 32 || pos_b < 0 || pos_b >= 32)
        return -INT64_C(2147483649);
    std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(data));
    const std::uint32_t mask_a = UINT32_C(1) << static_cast<unsigned>(pos_a);
    const std::uint32_t mask_b = UINT32_C(1) << static_cast<unsigned>(pos_b);
    const std::uint32_t bit_a = (bits >> static_cast<unsigned>(pos_a)) & UINT32_C(1);
    const std::uint32_t bit_b = (bits >> static_cast<unsigned>(pos_b)) & UINT32_C(1);
    if (bit_a != bit_b) bits ^= mask_a ^ mask_b;
    return sign_extend_u32(bits);
}
