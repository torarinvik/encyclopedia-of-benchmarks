#include <stdint.h>

#define MAX_INPUT 1000000000

int64_t reverse_number(int64_t number)
{
    if (number < 0 || number > MAX_INPUT) return -1;
    int64_t reversed = 0;
    while (number > 0) {
        reversed = reversed * 10 + number % 10;
        number /= 10;
    }
    return reversed;
}
