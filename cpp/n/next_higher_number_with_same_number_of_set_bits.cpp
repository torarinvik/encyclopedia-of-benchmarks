// Port of the pinned C++/Java next-higher-same-popcount bit formula.
#include <cstdint>

extern "C" std::int64_t next_higher_number_with_same_number_of_set_bits(std::int64_t input) noexcept
{
    if (input < 1 || input > 1'073'741'823) return -1;
    const std::int64_t right_one = input & -input;
    const std::int64_t next_higher = input + right_one;
    std::int64_t packed_ones = (input ^ next_higher) / right_one;
    packed_ones >>= 2;
    return next_higher | packed_ones;
}
