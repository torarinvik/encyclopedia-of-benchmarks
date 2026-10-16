#include <stdint.h>

int64_t problem191(int64_t days)
{
    if (days < 0 || days > 65) return -1;
    int64_t ways[396] = {0};
    for (int absent = 0; absent <= 1; ++absent)
        for (int late = 0; late <= 2; ++late)
            ways[absent * 3 + late] = 1;
    for (int64_t remaining = 1; remaining <= days; ++remaining) {
        for (int absent = 0; absent <= 1; ++absent) {
            for (int late = 0; late <= 2; ++late) {
                const int64_t previous = (remaining - 1) * 6;
                const int64_t late_state = late < 2 ? ways[previous + absent * 3 + late + 1] : 0;
                const int64_t absent_state = absent == 0 ? ways[previous + 3] : 0;
                const int64_t on_time_state = ways[previous + absent * 3];
                ways[remaining * 6 + absent * 3 + late] = late_state + absent_state + on_time_state;
            }
        }
    }
    return ways[days * 6];
}
