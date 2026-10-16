#include <stddef.h>
#include <stdint.h>
int64_t tilingproblem(const int64_t *input, size_t length) {
    if (!input || length != 1 || input[0] < 0 || input[0] > 91) return -1;
    int64_t previous = 1, current = 1;
    for (int64_t width = 2; width <= input[0]; ++width) { int64_t next = previous + current; previous = current; current = next; }
    return current;
}
