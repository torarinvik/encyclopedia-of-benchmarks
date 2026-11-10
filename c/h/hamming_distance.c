#include <stdint.h>

int64_t hamming_distance(uint64_t left, uint64_t right)
{
    return __builtin_popcountll(left ^ right);
}
