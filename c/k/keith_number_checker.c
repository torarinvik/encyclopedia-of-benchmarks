/* Preserve the digit-window recurrence used by the pinned C# checker. */
#include <stdint.h>
#include <stdlib.h>

int64_t keith_number_checker(int64_t number)
{
    if (number < 2 || number > 1000) return -1;
    const int64_t original = number;
    int64_t temp = number;
    int64_t digits = 0;
    while (temp != 0) {
        ++digits;
        temp /= 10;
    }

    int64_t *terms = (int64_t *)calloc((size_t)number, sizeof(*terms));
    if (terms == NULL) return -1;
    temp = number;
    for (int64_t i = digits - 1; i >= 0; --i) {
        terms[i] = temp % 10;
        temp /= 10;
    }

    int64_t sum = 0;
    int64_t k = digits;
    while (sum < original) {
        sum = 0;
        for (int64_t j = 1; j <= digits; ++j) sum += terms[k - j];
        terms[k++] = sum;
    }
    free(terms);
    return sum == original ? 1 : 0;
}
