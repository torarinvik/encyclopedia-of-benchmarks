#include <stdbool.h>
#include <stdint.h>

static bool solve(int64_t chain[32], int length, int64_t goal, int depth)
{
    const int64_t last = chain[length - 1];
    for (int index = 0; index < length; ++index) {
        const int64_t next = chain[index] + last;
        if (next == goal) return true;
        if (next > goal) break;
        if (length < depth) {
            chain[length] = next;
            if (solve(chain, length + 1, goal, depth)) return true;
        }
    }
    return false;
}

int64_t problem122(int64_t maximum)
{
    if (maximum < 0 || maximum > 200) return -1;
    int64_t total = 0;
    for (int64_t goal = 2; goal <= maximum; ++goal) {
        int depth = 0;
        int64_t chain[32] = {1};
        do { ++depth; chain[0] = 1; } while (!solve(chain, 1, goal, depth));
        total += depth;
    }
    return total;
}
