// 1 when the inputs are equal; otherwise 0.
#include <cstdint>

extern "C" std::int64_t xnor_gate(std::uint64_t left, std::uint64_t right) noexcept
{
    return static_cast<std::int64_t>(1 - (left ^ right));
}
