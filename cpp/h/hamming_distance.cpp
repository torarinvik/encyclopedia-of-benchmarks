/* Portable Hamming distance over two unsigned 64-bit values. */
#include <cstdint>

extern "C" std::int64_t hamming_distance(std::uint64_t left, std::uint64_t right) noexcept
{
    std::int64_t count = 0;
    while (left != 0 || right != 0) {
        if ((left & std::uint64_t{1}) != (right & std::uint64_t{1})) ++count;
        left >>= 1;
        right >>= 1;
    }
    return count;
}
