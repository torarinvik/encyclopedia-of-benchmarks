// 1 only when at least one input is 0; 0 when both are 1.
#include <cstdint>

extern "C" std::int64_t nand_gate(std::uint64_t left, std::uint64_t right) noexcept
{
    return static_cast<std::int64_t>(1 - (left & right));
}
