// 1 when either input is 1; otherwise 0.
#include <cstdint>

extern "C" std::int64_t or_gate(std::uint64_t left, std::uint64_t right) noexcept
{
    return static_cast<std::int64_t>(left | right);
}
