#include <stddef.h>
#include <stdint.h>

#define MAX_EGGS 8
#define MAX_FLOORS 32

int64_t egg_dropping_puzzle(const int64_t *input, size_t length) {
    if (input == NULL || length != 2) return -1;
    const int64_t eggs_value = input[0];
    const int64_t floors_value = input[1];
    if (eggs_value < 1 || eggs_value > MAX_EGGS || floors_value < 1 || floors_value > MAX_FLOORS) return -1;

    const size_t eggs = (size_t)eggs_value;
    const size_t floors = (size_t)floors_value;
    int64_t dp[MAX_EGGS + 1][MAX_FLOORS + 1] = {{0}};
    for (size_t egg = 1; egg <= eggs; ++egg) dp[egg][1] = 1;
    for (size_t floor_count = 1; floor_count <= floors; ++floor_count) dp[1][floor_count] = (int64_t)floor_count;

    for (size_t egg = 2; egg <= eggs; ++egg) {
        for (size_t floor_count = 2; floor_count <= floors; ++floor_count) {
            int64_t best = MAX_FLOORS + 1;
            for (size_t drop_floor = 1; drop_floor <= floor_count; ++drop_floor) {
                const int64_t broken = dp[egg - 1][drop_floor - 1];
                const int64_t survives = dp[egg][floor_count - drop_floor];
                const int64_t worst = broken > survives ? broken : survives;
                const int64_t candidate = worst + 1;
                if (candidate < best) best = candidate;
            }
            dp[egg][floor_count] = best;
        }
    }
    return dp[eggs][floors];
}
