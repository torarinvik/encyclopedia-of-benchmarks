#include <stdint.h>

int64_t gray_to_binary(int64_t gray)
{
    if (gray < 0) return -1;
    int64_t binary = gray;
    gray >>= 1;
    while (gray != 0) {
        binary ^= gray;
        gray >>= 1;
    }
    return binary;
}
