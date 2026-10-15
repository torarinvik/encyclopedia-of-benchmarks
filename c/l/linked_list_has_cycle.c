/* Floyd cycle detection over a portable successor-index representation. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 100000

static int valid_successors(const int64_t *next, size_t length)
{
    if (length > MAX_NODES || (length != 0 && next == NULL)) return 0;
    for (size_t i = 0; i < length; ++i)
        if (next[i] < -1 || next[i] >= (int64_t)length) return 0;
    return 1;
}

static int64_t successor(const int64_t *next, int64_t node)
{
    return node < 0 ? -1 : next[(size_t)node];
}

/* Input is next-node indices; -1 means null and node 0 is the head.
   Returns 1 for a cycle, 0 for an acyclic list, and -1 for malformed input. */
int64_t linked_list_has_cycle(const int64_t *next, size_t length)
{
    if (!valid_successors(next, length)) return -1;
    if (length == 0) return 0;
    int64_t slow = 0, fast = 0;
    while (fast >= 0) {
        int64_t first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) return 1;
    }
    return 0;
}
