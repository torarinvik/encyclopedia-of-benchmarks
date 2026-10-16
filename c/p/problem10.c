#include <stdint.h>

int64_t problem10(int64_t limit)
{
    if (limit < 0 || limit > 2000000) return -1;
    uint8_t composite[1000000] = {0};
    const int64_t odd_count = limit / 2;
    int64_t sum = limit > 2 ? 2 : 0;
    for (int64_t prime = 3; prime * prime < limit; prime += 2) {
        const int64_t prime_index = prime / 2;
        if (!composite[prime_index]) {
            for (int64_t index = prime * prime / 2; index < odd_count; index += prime)
                composite[index] = 1;
        }
    }
    for (int64_t index = 1; index < odd_count; ++index)
        if (!composite[index]) sum += 2 * index + 1;
    return sum;
}
