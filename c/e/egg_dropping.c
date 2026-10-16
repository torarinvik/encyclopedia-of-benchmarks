#include <stddef.h>
#include <stdint.h>

#define MAX_EGGS 12
#define MAX_FLOORS 128
#define FLOOR_WIDTH (MAX_FLOORS + 1)

int64_t egg_dropping(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return INT64_MIN;
    if (input[0] < 1 || input[0] > MAX_EGGS ||
        input[1] < 1 || input[1] > MAX_FLOORS) return INT64_MIN;

    const size_t eggs = (size_t)input[0];
    const size_t floors = (size_t)input[1];
    int64_t dp[(MAX_EGGS + 1) * FLOOR_WIDTH] = {0};

    for (size_t egg = 1; egg <= eggs; ++egg) dp[egg * FLOOR_WIDTH + 1] = 1;
    for (size_t floor = 1; floor <= floors; ++floor) dp[FLOOR_WIDTH + floor] = (int64_t)floor;
    for (size_t egg = 2; egg <= eggs; ++egg) {
        for (size_t floor = 2; floor <= floors; ++floor) {
            int64_t best = INT64_MAX;
            for (size_t drop = 1; drop <= floor; ++drop) {
                const int64_t breaks = dp[(egg - 1) * FLOOR_WIDTH + drop - 1];
                const int64_t survives = dp[egg * FLOOR_WIDTH + floor - drop];
                const int64_t worst = 1 + (breaks > survives ? breaks : survives);
                if (worst < best) best = worst;
            }
            dp[egg * FLOOR_WIDTH + floor] = best;
        }
    }
    return dp[eggs * FLOOR_WIDTH + floors];
}
