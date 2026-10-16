/* Return the Peter-over-Colin win probability in units of 1e-7. */
#include <stdint.h>
#include <string.h>

#define MAX_TOTAL 36
#define SCALE INT64_C(10000000)

static void distribution(int64_t sides, int64_t dice, int64_t output[MAX_TOTAL + 1])
{
    int64_t current[MAX_TOTAL + 1] = {0}, next[MAX_TOTAL + 1];
    current[0] = 1;
    for (int64_t die = 0; die < dice; ++die) {
        memset(next, 0, sizeof(next));
        for (int64_t total = 0; total <= MAX_TOTAL; ++total) if (current[total] != 0)
            for (int64_t face = 1; face <= sides; ++face) next[total + face] += current[total];
        memcpy(current, next, sizeof(current));
    }
    memcpy(output, current, sizeof(current));
}

int64_t problem205(int64_t placeholder)
{
    if (placeholder != 0) return -1;
    int64_t peter[MAX_TOTAL + 1], colin[MAX_TOTAL + 1];
    distribution(4, 9, peter);
    distribution(6, 6, colin);
    int64_t wins = 0, colin_below = 0;
    for (int64_t total = 0; total <= MAX_TOTAL; ++total) {
        if (total >= 9) wins += peter[total] * colin_below;
        colin_below += colin[total];
    }
    const int64_t games = INT64_C(262144) * INT64_C(46656);
    const int64_t scaled = wins * SCALE;
    int64_t rounded = scaled / games;
    const int64_t remainder = scaled % games;
    if (2 * remainder > games || (2 * remainder == games && rounded % 2 != 0)) ++rounded;
    return rounded;
}
