#include <stdint.h>

#define MIN_THRESHOLD INT64_C(-2147483648)
#define MAX_THRESHOLD INT64_C(1000000000)

int64_t so1(int64_t threshold)
{
    if (threshold < MIN_THRESHOLD || threshold > MAX_THRESHOLD) return -1;

    int64_t first = 1;
    int64_t second = 2;
    int64_t sum = 0;
    while (second <= threshold) {
        if (second % 2 == 0) sum += second;
        const int64_t temporary = first;
        first = second;
        second = temporary + first;
    }
    return sum;
}
