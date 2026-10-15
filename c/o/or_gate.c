/* 1 when either input is 1; otherwise 0. */
#include <stdint.h>

int64_t or_gate(uint64_t left, uint64_t right)
{
    return (int64_t)(left | right);
}
