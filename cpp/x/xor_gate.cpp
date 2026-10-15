// 1 when the inputs differ; otherwise 0.
#include <cstdint>

extern "C" std::int64_t xor_gate(std::uint64_t left, std::uint64_t right) noexcept
{
    return static_cast<std::int64_t>(left ^ right);
}
