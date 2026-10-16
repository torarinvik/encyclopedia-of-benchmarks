#include <cstdint>

extern "C" std::int64_t logarithm(std::int64_t input) noexcept
{
    if (input < 1 || input > 4'294'967'295LL) return -1;
    std::uint32_t value = static_cast<std::uint32_t>(input);
    std::int64_t result = 0;
    if ((value & 0xFFFF0000U) != 0) { value >>= 16; result += 16; }
    if ((value & 0x0000FF00U) != 0) { value >>= 8; result += 8; }
    if ((value & 0x000000F0U) != 0) { value >>= 4; result += 4; }
    if ((value & 0x0000000CU) != 0) { value >>= 2; result += 2; }
    if ((value & 0x00000002U) != 0) result += 1;
    return result;
}
