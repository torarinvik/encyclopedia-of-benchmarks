/* Match the product's decimal digits against the combined factor digits. */
#include <stdint.h>

static unsigned decimal_length(uint64_t value)
{
    unsigned length = 0;
    do { ++length; value /= 10; } while (value != 0);
    return length;
}

int64_t vampire_number(uint64_t left, uint64_t right)
{
    if (left < 1 || left > 9999 || right < 1 || right > 9999) return -1;
    if (decimal_length(left) != decimal_length(right)) return 0;
    int counts[10] = {0};
    uint64_t product = left * right;
    while (product != 0) { ++counts[product % 10]; product /= 10; }
    while (left != 0) { --counts[left % 10]; left /= 10; }
    while (right != 0) { --counts[right % 10]; right /= 10; }
    for (int digit = 0; digit < 10; ++digit) if (counts[digit] != 0) return 0;
    return 1;
}
