/* 1 when the inputs differ; otherwise 0. */
#include <stdint.h>

int64_t xor_gate(uint64_t left, uint64_t right)
{
    return (int64_t)(left ^ right);
}
