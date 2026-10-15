/* Find the cycle entrance induced by the duplicate value. */
#include <stddef.h>
#include <stdint.h>

int64_t find_duplicate_number(const int64_t *values, size_t length)
{
    if (length < 2 || length > 100001) return -1;
    const size_t maximum_value = length - 1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 1 || (uint64_t)values[index] > maximum_value) return -1;
    }

    size_t slow = (size_t)values[0];
    size_t fast = (size_t)values[0];
    do {
        slow = (size_t)values[slow];
        fast = (size_t)values[(size_t)values[fast]];
    } while (slow != fast);

    slow = (size_t)values[0];
    while (slow != fast) {
        slow = (size_t)values[slow];
        fast = (size_t)values[fast];
    }
    return (int64_t)slow;
}
