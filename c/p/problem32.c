#include <stdbool.h>
#include <stdint.h>

static bool next_permutation(int digits[9])
{
    int pivot = 7;
    while (pivot >= 0 && digits[pivot] >= digits[pivot + 1]) --pivot;
    if (pivot < 0) return false;
    int successor = 8;
    while (digits[successor] <= digits[pivot]) --successor;
    int temporary = digits[pivot];
    digits[pivot] = digits[successor];
    digits[successor] = temporary;
    for (int left = pivot + 1, right = 8; left < right; ++left, --right) {
        temporary = digits[left];
        digits[left] = digits[right];
        digits[right] = temporary;
    }
    return true;
}

int64_t problem32(int64_t ignored)
{
    if (ignored != 0) return -1;
    int digits[9] = {1, 2, 3, 4, 5, 6, 7, 8, 9};
    bool seen[10000] = {false};
    do {
        const int product = digits[5] * 1000 + digits[6] * 100 + digits[7] * 10 + digits[8];
        const int two_digit = digits[0] * 10 + digits[1];
        const int three_digit = digits[2] * 100 + digits[3] * 10 + digits[4];
        const int four_digit = digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4];
        if (two_digit * three_digit == product) seen[product] = true;
        if (digits[0] * four_digit == product) seen[product] = true;
    } while (next_permutation(digits));
    int64_t sum = 0;
    for (int product = 0; product < 10000; ++product) if (seen[product]) sum += product;
    return sum;
}
