/* (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place. */
#include <stddef.h>
#include <stdint.h>
int64_t prolangs_c_simulator_shiftr(const int64_t *v, size_t n) {
    if (v == NULL || n != 2 || v[0] < 0 || v[0] > 255 || v[1] < 0 || v[1] > 0xFFFFFF) return -1;
    int64_t operand=v[0];
    if ((operand >> 4) >= 10) return -1;
    unsigned shift=(unsigned)(operand & 15)+1u;
    uint32_t value=(uint32_t)v[1], result=value >> shift;
    if (value & 0x800000u) result |= ((1u << shift)-1u) << (24u-shift);
    return result & 0xFFFFFFu;
}
