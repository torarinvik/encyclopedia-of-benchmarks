#include <stdint.h>

int64_t problem3(int64_t number)
{
    if (number < 2 || number > INT64_C(600851475143)) return -1;
    int64_t remaining = number;
    int64_t largest = 1;
    for (int64_t factor = 2; factor <= remaining / factor;) {
        if (remaining % factor == 0) {
            largest = factor;
            remaining /= factor;
        } else {
            ++factor;
        }
    }
    return remaining > 1 ? remaining : largest;
}
