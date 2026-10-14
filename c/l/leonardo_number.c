/* Iteratively compute L(0)=L(1)=1 and L(n)=L(n-1)+L(n-2)+1. */
#include <stdint.h>

int64_t leonardo_number(int64_t input)
{
    if (input < 0 || input > 89) return -1;
    int64_t previous = 1;
    int64_t current = 1;
    for (int64_t index = 2; index <= input; ++index) {
        const int64_t next = current + previous + 1;
        previous = current;
        current = next;
    }
    return current;
}
