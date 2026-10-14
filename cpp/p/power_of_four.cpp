// Positive powers of four within the signed 32-bit source domain.
#include <cstdint>
extern "C" int64_t power_of_four(int64_t value)
{
    if (value < INT32_MIN || value > INT32_MAX) return -1;
    if (value <= 0 || (value & (value - 1)) != 0) return 0;
    return (value & 0x55555555LL) != 0;
}
