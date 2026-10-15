/* Add nonnegative integers by recursively propagating XOR carries. */
#include <stdint.h>

static int64_t add_recursive(int64_t first, int64_t second)
{
    const int64_t bitwise_sum = first ^ second;
    const int64_t carry = first & second;
    return carry == 0 ? bitwise_sum : add_recursive(bitwise_sum, carry << 1);
}

int64_t bitwise_addition_recursive(int64_t first, int64_t second)
{
    if (first < 0 || first > 2147483647 || second < 0 || second > 2147483647) return -1;
    return add_recursive(first, second);
}
