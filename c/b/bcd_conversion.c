#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)

int64_t bcd_conversion(int64_t decimal)
{
    if (decimal < 0 || decimal > 9999) return INVALID_RESULT;
    int64_t bcd = 0;
    int64_t shift = 0;
    while (decimal > 0) {
        const int64_t digit = decimal % 10;
        bcd |= digit << (shift * 4);
        decimal /= 10;
        ++shift;
    }
    return bcd;
}
