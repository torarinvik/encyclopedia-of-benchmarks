/* Test whether n is a positive Dudeney number: cube root equals digit sum. */
#include <stdint.h>

int64_t dudeney_number(int64_t number)
{
    if (number <= 0 || number > INT32_MAX) return -1;
    int64_t low = 1;
    int64_t high = 1290;
    int64_t root = 0;
    while (low <= high) {
        const int64_t middle = low + (high - low) / 2;
        const int64_t cube = middle * middle * middle;
        if (cube == number) { root = middle; break; }
        if (cube < number) low = middle + 1;
        else high = middle - 1;
    }
    if (root == 0) return 0;
    int64_t remaining = number;
    int64_t sum = 0;
    while (remaining > 0) { sum += remaining % 10; remaining /= 10; }
    return sum == root ? 1 : 0;
}
