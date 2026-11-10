#include <cstdint>

extern "C" std::int64_t hamming_distance(std::uint64_t left, std::uint64_t right) noexcept
{
    return __builtin_popcountll(left ^ right);
}
