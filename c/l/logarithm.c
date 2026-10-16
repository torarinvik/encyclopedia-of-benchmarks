#include <stdint.h>

static int64_t log_base2(uint32_t value)
{
    int64_t result = 0;
    if ((value & UINT32_C(0xFFFF0000)) != 0) { value >>= 16; result += 16; }
    if ((value & UINT32_C(0x0000FF00)) != 0) { value >>= 8; result += 8; }
    if ((value & UINT32_C(0x000000F0)) != 0) { value >>= 4; result += 4; }
    if ((value & UINT32_C(0x0000000C)) != 0) { value >>= 2; result += 2; }
    if ((value & UINT32_C(0x00000002)) != 0) result += 1;
    return result;
}

int64_t logarithm(int64_t input)
{
    if (input < 1 || input > 4294967295LL) return -1;
    return log_base2((uint32_t)input);
}
