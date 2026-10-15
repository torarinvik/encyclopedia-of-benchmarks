/* Return the next larger positive integer with the same population count. */
#include <stdint.h>

int64_t next_higher_number_with_same_number_of_set_bits(int64_t input)
{
    if (input < 1 || input > 1073741823) return -1;
    const int64_t right_one = input & -input;
    const int64_t next_higher = input + right_one;
    int64_t packed_ones = (input ^ next_higher) / right_one;
    packed_ones >>= 2;
    return next_higher | packed_ones;
}
