#include <stdint.h>

#define MAX_INPUT INT64_C(30000)

/* Count nondecreasing vowel strings via the pinned closed-form product. */
int64_t count_sorted_vowel_strings(int64_t n)
{
    if (n < 0 || n > MAX_INPUT) return -1;
    return (n + 4) * (n + 3) * (n + 2) * (n + 1) / 24;
}
