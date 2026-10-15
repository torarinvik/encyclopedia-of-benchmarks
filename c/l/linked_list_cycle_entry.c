/* Floyd cycle-entry search over a portable successor-index representation. */
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

/* Returns the cycle-entry node index, -1 if acyclic, and -2 for malformed input. */
int64_t linked_list_cycle_entry(const int64_t *next, size_t length)
{
    if (!valid_successors(next, length)) return -2;
    if (length == 0) return -1;
    int64_t slow = 0, fast = 0;
    int meeting = 0;
    while (fast >= 0) {
        int64_t first = successor(next, fast);
        if (first < 0) break;
        slow = successor(next, slow);
        fast = successor(next, first);
        if (slow == fast) { meeting = 1; break; }
    }
    if (!meeting) return -1;
    int64_t entry = 0;
    while (entry != slow) {
        entry = successor(next, entry);
        slow = successor(next, slow);
    }
    return entry;
}
