#include <stddef.h>
#include <stdint.h>

static const uint8_t D[100] = {
    0,1,2,3,4,5,6,7,8,9, 1,2,3,4,0,6,7,8,9,5,
    2,3,4,0,1,7,8,9,5,6, 3,4,0,1,2,8,9,5,6,7,
    4,0,1,2,3,9,5,6,7,8, 5,9,8,7,6,0,4,3,2,1,
    6,5,9,8,7,1,0,4,3,2, 7,6,5,9,8,2,1,0,4,3,
    8,7,6,5,9,3,2,1,0,4, 9,8,7,6,5,4,3,2,1,0
};
static const uint8_t P[80] = {
    0,1,2,3,4,5,6,7,8,9, 1,5,7,6,2,8,3,0,9,4,
    5,8,0,3,7,9,6,1,4,2, 8,9,1,6,0,4,3,5,2,7,
    9,4,5,3,1,2,6,8,7,0, 4,2,8,6,5,7,3,9,0,1,
    2,7,9,3,8,0,6,4,1,5, 7,0,4,6,9,1,3,2,5,8
};

int64_t verhoeff(const int64_t *digits, size_t length)
{
    if (digits == NULL || length == 0 || length > 1024) return -1;
    for (size_t i = 0; i < length; ++i) if (digits[i] < 0 || digits[i] > 9) return -1;
    uint8_t checksum = 0;
    for (size_t i = 0; i < length; ++i) {
        const uint8_t digit = (uint8_t)digits[length - i - 1];
        checksum = D[checksum * 10 + P[(i % 8) * 10 + digit]];
    }
    return checksum == 0 ? 1 : 0;
}
