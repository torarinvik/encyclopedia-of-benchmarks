#include <stddef.h>
#include <stdint.h>

int64_t sum_of_two_integers(const int64_t *input, size_t length)
{
    if (input == NULL || length != 2) return -1;
    if (input[0] < INT32_MIN || input[0] > INT32_MAX
        || input[1] < INT32_MIN || input[1] > INT32_MAX) return -1;

    uint64_t partial = (uint64_t)input[0];
    uint64_t carry = (uint64_t)input[1];
    while (carry != 0) {
        const uint64_t next_carry = partial & carry;
        partial ^= carry;
        carry = next_carry << 1;
    }

    if (partial <= INT64_MAX) return (int64_t)partial;
    return -1 - (int64_t)(~partial);
}
