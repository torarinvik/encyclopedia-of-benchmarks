/* Exact perfect-square check using bounded integer binary search. */
#include <stdint.h>

int64_t perfect_square(int64_t input)
{
    if (input < 0) return 0;
    if (input < 2) return 1;
    const uint64_t number = (uint64_t)input;
    if (((0x0213ULL >> (number & 15)) & 1) == 0) return 0;
    uint64_t low = 1;
    const uint64_t root_limit = number <= UINT32_MAX ? 65535 : UINT64_C(3037000499);
    uint64_t high = number / 2 < root_limit ? number / 2 : root_limit;
    while (low <= high) {
        const uint64_t middle = (low + high) >> 1;
        const uint64_t square = middle * middle;
        if (square == number) return 1;
        if (square < number) low = middle + 1;
        else high = middle - 1;
    }
    return 0;
}
