/* Clean-room bounded knapsack by binary grouping. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TYPES 16
#define MAX_CAPACITY 64
#define MAX_INPUT 51

int64_t bounded_knapsack_binary_grouping(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t capacity_value = input[1];
    if (n_value < 0 || n_value > MAX_TYPES || capacity_value < 0 || capacity_value > MAX_CAPACITY)
        return -1;
    const size_t n = (size_t)n_value;
    const size_t capacity = (size_t)capacity_value;
    if (length != 2 + 3 * n) return -1;
    for (size_t item = 0; item < n; ++item) {
        const int64_t weight = input[2 + 3 * item];
        const int64_t value = input[3 + 3 * item];
        const int64_t count = input[4 + 3 * item];
        if (weight < 1 || weight > 16 || value < 0 || value > 100 || count < 0 || count > 16)
            return -1;
    }

    int64_t best[MAX_CAPACITY + 1] = {0};
    for (size_t item = 0; item < n; ++item) {
        const size_t weight = (size_t)input[2 + 3 * item];
        const int64_t value = input[3 + 3 * item];
        size_t remaining = (size_t)input[4 + 3 * item];
        size_t bundle_size = 1;
        while (remaining > 0) {
            const size_t copies = bundle_size < remaining ? bundle_size : remaining;
            const size_t bundle_weight = weight * copies;
            const int64_t bundle_value = value * (int64_t)copies;
            if (bundle_weight <= capacity) {
                for (size_t limit = capacity; limit >= bundle_weight; --limit) {
                    const int64_t candidate = best[limit - bundle_weight] + bundle_value;
                    if (candidate > best[limit]) best[limit] = candidate;
                }
            }
            remaining -= copies;
            bundle_size *= 2;
        }
    }
    return best[capacity];
}
