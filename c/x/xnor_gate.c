/* 1 when the inputs are equal; otherwise 0. */
#include <stdint.h>

int64_t xnor_gate(uint64_t left, uint64_t right)
{
    return (int64_t)(1 - (left ^ right));
}
