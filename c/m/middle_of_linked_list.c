/* Return the second middle node's index in a successor-index list. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 100000

int64_t middle_of_linked_list(const int64_t *next, size_t length)
{
    if (length > MAX_NODES || (length != 0 && next == NULL)) return -2;
    for (size_t index = 0; index < length; ++index)
        if (next[index] < -1 || next[index] >= (int64_t)length) return -2;
    if (length == 0) return -1;

    int64_t slow = 0, fast = 0;
    while (fast >= 0) {
        const int64_t first = next[(size_t)fast];
        if (first < 0) break;
        slow = next[(size_t)slow];
        fast = next[(size_t)first];
        if (slow == fast) return -2;
    }

    slow = 0;
    fast = 0;
    while (fast >= 0) {
        const int64_t first = next[(size_t)fast];
        if (first < 0) break;
        slow = next[(size_t)slow];
        fast = next[(size_t)first];
    }
    return slow;
}
