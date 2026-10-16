/* Two-input Boolean implication over the benchmark's 0/1 domain. */
#include <stdint.h>

int64_t imply_gate(uint64_t left, uint64_t right)
{
    return (int64_t)(left == 0 || right == 1);
}
