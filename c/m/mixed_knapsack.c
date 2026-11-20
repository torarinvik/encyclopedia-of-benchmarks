/* Clean-room heterogeneous-mode knapsack. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TYPES 16
#define MAX_CAPACITY 64
#define MAX_INPUT 67

int64_t mixed_knapsack(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    const int64_t capacity_value = input[1];
    if (n_value < 0 || n_value > MAX_TYPES || capacity_value < 0 || capacity_value > MAX_CAPACITY)
        return -1;
    const size_t n = (size_t)n_value;
    const size_t capacity = (size_t)capacity_value;
    if (length != 2 + 4 * n) return -1;
    for (size_t item = 0; item < n; ++item) {
        const int64_t mode = input[2 + 4 * item];
        const int64_t weight = input[3 + 4 * item];
        const int64_t value = input[4 + 4 * item];
        const int64_t limit = input[5 + 4 * item];
        if (mode < 0 || mode > 2 || weight < 1 || weight > 16 || value < 0 || value > 100)
            return -1;
        if ((mode == 0 && limit != 1) || (mode == 1 && limit != 0)
            || (mode == 2 && (limit < 0 || limit > 16))) return -1;
    }

    int64_t best[MAX_CAPACITY + 1] = {0};
    for (size_t item = 0; item < n; ++item) {
        const int64_t mode = input[2 + 4 * item];
        const size_t weight = (size_t)input[3 + 4 * item];
        const int64_t value = input[4 + 4 * item];
        if (mode == 0) {
            for (size_t cap = capacity; cap >= weight; --cap) {
                const int64_t candidate = best[cap - weight] + value;
                if (candidate > best[cap]) best[cap] = candidate;
                if (cap == weight) break;
            }
        } else if (mode == 1) {
            for (size_t cap = weight; cap <= capacity; ++cap) {
                const int64_t candidate = best[cap - weight] + value;
                if (candidate > best[cap]) best[cap] = candidate;
            }
        } else {
            size_t remaining = (size_t)input[5 + 4 * item];
            size_t bundle_size = 1;
            while (remaining > 0) {
                const size_t copies = bundle_size < remaining ? bundle_size : remaining;
                const size_t bundle_weight = copies * weight;
                const int64_t bundle_value = (int64_t)copies * value;
                if (bundle_weight <= capacity) {
                    for (size_t cap = capacity; cap >= bundle_weight; --cap) {
                        const int64_t candidate = best[cap - bundle_weight] + bundle_value;
                        if (candidate > best[cap]) best[cap] = candidate;
                        if (cap == bundle_weight) break;
                    }
                }
                remaining -= copies;
                bundle_size *= 2;
            }
        }
    }
    return best[capacity];
}
