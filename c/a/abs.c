/* Return the signed 64-bit magnitude, or -1 when it cannot be represented. */
#include <stdint.h>

int64_t abs_i64(int64_t input)
{
    if (input == INT64_MIN) return -1;
    return input < 0 ? -input : input;
}
