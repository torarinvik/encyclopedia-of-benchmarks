// Two-input Boolean implication over the benchmark's 0/1 domain.
#include <cstdint>

extern "C" std::int64_t imply_gate(std::uint64_t left, std::uint64_t right) noexcept
{
    return static_cast<std::int64_t>(left == 0 || right == 1);
}
