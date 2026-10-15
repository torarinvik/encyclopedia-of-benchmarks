/* 1 only when at least one input is 0; 0 when both are 1. */
#include <stdint.h>

int64_t nand_gate(uint64_t left, uint64_t right)
{
    return (int64_t)(1 - (left & right));
}
