/* Minimum partition difference with bottom-up subset-sum reachability. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VALID_INPUT_LENGTH 64
#define MAX_TOTAL_SUM 4096

int64_t minimum_sum_partition(const int64_t *input, size_t length)
{
    if (length > MAX_VALID_INPUT_LENGTH || (input == NULL && length != 0)) return -1;

    int64_t total = 0;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        if (value < 0 || value > MAX_TOTAL_SUM || total > MAX_TOTAL_SUM - value) return -1;
        total += value;
    }

    const size_t target = (size_t)(total / 2);
    uint8_t reachable[MAX_TOTAL_SUM / 2 + 1] = {0};
    reachable[0] = 1;
    size_t closest = 0;
    for (size_t index = 0; index < length; ++index) {
        const size_t value = (size_t)input[index];
        for (size_t sum = target; sum > 0; --sum) {
            if (value <= sum && reachable[sum - value] != 0) reachable[sum] = 1;
            if (reachable[sum] != 0 && sum > closest) closest = sum;
        }
    }
    return total - 2 * (int64_t)closest;
}
