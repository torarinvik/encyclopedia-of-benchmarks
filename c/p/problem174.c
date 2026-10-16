/* Count tile counts represented by at most n_limit square laminae. */
#include <stdint.h>
#include <stdlib.h>

#define MAX_TILES INT64_C(1000000)

static int64_t problem174_ceil_sqrt(int64_t value)
{
    if (value <= 0) return 0;
    int64_t root = value;
    int64_t next = (root + value / root) / 2;
    while (next < root) {
        root = next;
        next = (root + value / root) / 2;
    }
    return root * root == value ? root : root + 1;
}

int64_t problem174(int64_t t_limit, int64_t n_limit)
{
    if (t_limit > MAX_TILES) return -1;
    if (t_limit < 0) return 0;
    uint8_t *count = (uint8_t *)calloc((size_t)t_limit + 1, sizeof(uint8_t));
    if (count == NULL) return -1;
    for (int64_t outer_width = 3; outer_width < t_limit / 4 + 2; ++outer_width) {
        const int64_t outer_area = outer_width * outer_width;
        int64_t hole_lower = 1;
        if (outer_area > t_limit) {
            hole_lower = problem174_ceil_sqrt(outer_area - t_limit);
            if (hole_lower < 1) hole_lower = 1;
        }
        if ((outer_width - hole_lower) % 2 != 0) ++hole_lower;
        for (int64_t hole_width = hole_lower; hole_width < outer_width - 1; hole_width += 2) {
            const int64_t tiles = outer_area - hole_width * hole_width;
            ++count[(size_t)tiles];
        }
    }
    int64_t answer = 0;
    for (int64_t tiles = 1; tiles <= t_limit; ++tiles)
        answer += count[(size_t)tiles] >= 1 && count[(size_t)tiles] <= n_limit;
    free(count);
    return answer;
}
