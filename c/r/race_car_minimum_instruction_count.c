#include <stddef.h>
#include <stdint.h>

int64_t race_car_minimum_instruction_count(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > 2 || length != 1) return -1;
    const int64_t target_value = input[0];
    if (target_value < 0 || target_value > 127) return -1;
    const size_t target = (size_t)target_value;
    int32_t distance[128] = {0};

    for (size_t position = 1; position <= target; ++position) {
        size_t run = 0;
        size_t upper_power = 1;
        while (upper_power <= position) {
            upper_power <<= 1;
            ++run;
        }
        const size_t upper = upper_power - 1;
        if (position == upper) {
            distance[position] = (int32_t)run;
            continue;
        }

        int32_t best = (int32_t)(run + 1) + distance[upper - position];
        const size_t lower = (upper_power >> 1) - 1;
        for (size_t backward_run = 0; backward_run + 1 < run; ++backward_run) {
            const size_t backward_distance = ((size_t)1 << backward_run) - 1;
            const size_t remaining = position - (lower - backward_distance);
            const int32_t candidate = (int32_t)(run + backward_run + 1) + distance[remaining];
            if (candidate < best) best = candidate;
        }
        distance[position] = best;
    }
    return distance[target];
}
