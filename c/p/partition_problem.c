/* Equal-sum two-way partition using bottom-up subset-sum reachability. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 16
#define MAX_TOTAL 1024

int64_t partition_problem(const int64_t *input, size_t length)
{
    if (input == NULL || length == 0 || length > MAX_ITEMS) return -1;
    int64_t total = 0;
    for (size_t index = 0; index < length; ++index) {
        if (input[index] < 0 || input[index] > 256 || total > MAX_TOTAL - input[index]) return -1;
        total += input[index];
    }
    if ((total & 1) != 0) return 0;
    const size_t target = (size_t)(total / 2);
    uint8_t reachable[MAX_TOTAL + 1] = {0};
    reachable[0] = 1;
    for (size_t index = 0; index < length; ++index) {
        const size_t value = (size_t)input[index];
        if (value > target) continue;
        for (size_t sum = target;; --sum) {
            if (reachable[sum - value]) reachable[sum] = 1;
            if (sum == value) break;
        }
    }
    return reachable[target] ? 1 : 0;
}
