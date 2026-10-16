#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SLOTS 31
#define MAX_VALUE 1000000
#define EMPTY_MIN 1000001

int64_t maximum_sum_bst(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_SLOTS + 1) return -1;
    if (input[0] < 0 || input[0] > MAX_SLOTS || length != (size_t)input[0] + 1) return -1;
    const size_t count = (size_t)input[0];
    for (size_t i = 0; i < count; ++i) {
        if (input[i + 1] < -1 || input[i + 1] > MAX_VALUE) return -1;
        if (input[i + 1] != -1 && i > 0 && input[(i - 1) / 2 + 1] == -1) return -1;
    }
    if (count == 0) return 0;
    bool valid[MAX_SLOTS] = {0};
    int64_t subtree_min[MAX_SLOTS] = {0}, subtree_max[MAX_SLOTS] = {0};
    int64_t subtree_sum[MAX_SLOTS] = {0}, best[MAX_SLOTS] = {0};
    for (size_t remaining = count; remaining > 0; --remaining) {
        const size_t i = remaining - 1;
        if (input[i + 1] == -1) {
            valid[i] = true; subtree_min[i] = EMPTY_MIN; subtree_max[i] = -1;
            continue;
        }
        const size_t left = 2 * i + 1, right = left + 1;
        const bool left_valid = left >= count || valid[left];
        const bool right_valid = right >= count || valid[right];
        const int64_t left_max = left >= count ? -1 : subtree_max[left];
        const int64_t right_min = right >= count ? EMPTY_MIN : subtree_min[right];
        const int64_t left_min = left >= count ? EMPTY_MIN : subtree_min[left];
        const int64_t right_max = right >= count ? -1 : subtree_max[right];
        const int64_t left_sum = left >= count ? 0 : subtree_sum[left];
        const int64_t right_sum = right >= count ? 0 : subtree_sum[right];
        const int64_t left_best = left >= count ? 0 : best[left];
        const int64_t right_best = right >= count ? 0 : best[right];
        const int64_t value = input[i + 1];
        if (left_valid && right_valid && left_max < value && value < right_min) {
            valid[i] = true; subtree_min[i] = left_min < value ? left_min : value;
            subtree_max[i] = right_max > value ? right_max : value;
            subtree_sum[i] = left_sum + right_sum + value;
            best[i] = subtree_sum[i] > left_best ? subtree_sum[i] : left_best;
            if (right_best > best[i]) best[i] = right_best;
        } else {
            valid[i] = false; best[i] = left_best > right_best ? left_best : right_best;
        }
    }
    return best[0];
}
