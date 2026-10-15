// Sum of a full binomial row, computed as 2^n.
#include <cstdint>

extern "C" int64_t sum_of_binomial_coefficient(int64_t n)
{
    if (n < 0 || n > 30) return -1;
    return static_cast<int64_t>(1 << n);
}
