/* Clean-room Pisinger balanced-state subset-sum profile. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 32
#define MAX_TARGET 256
#define MAX_WEIGHT 12
#define MAX_PARSEABLE_INPUT_LENGTH 35

int64_t pisinger_bounded_weight_subset_sum(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t n_value = input[0];
    const int64_t target_value = input[1];
    if (n_value < 0 || n_value > MAX_ITEMS || target_value < 0 || target_value > MAX_TARGET) return -1;
    const size_t n = (size_t)n_value;
    if (length != n + 2) return -1;

    int32_t width = 0;
    for (size_t index = 0; index < n; ++index) {
        const int64_t weight = input[index + 2];
        if (weight < 1 || weight > MAX_WEIGHT) return -1;
        if (weight > width) width = (int32_t)weight;
    }
    if (n == 0) return 0;

    const int32_t target = (int32_t)target_value;
    int32_t prefix_sum = 0;
    size_t break_index = 0;
    while (break_index < n && prefix_sum + input[break_index + 2] <= target) {
        prefix_sum += (int32_t)input[break_index + 2];
        ++break_index;
    }
    if (break_index == n) return prefix_sum;

    int32_t previous[2 * MAX_WEIGHT];
    int32_t current[2 * MAX_WEIGHT];
    for (int32_t slot = 0; slot < 2 * width; ++slot) previous[slot] = -1;
    previous[prefix_sum + width - target - 1] = (int32_t)break_index;

    for (size_t item = break_index; item < n; ++item) {
        for (int32_t slot = 0; slot < 2 * width; ++slot) current[slot] = previous[slot];
        const int32_t weight = (int32_t)input[item + 2];
        for (int32_t slot = 0; slot < width; ++slot) {
            const int32_t destination = slot + weight;
            if (previous[slot] > current[destination]) current[destination] = previous[slot];
        }
        for (int32_t slot = 2 * width - 1; slot >= width; --slot) {
            int32_t first_item = previous[slot];
            if (first_item < 0) first_item = 0;
            const int32_t stop_item = current[slot];
            for (int32_t removed = first_item; removed < stop_item; ++removed) {
                const int32_t reduced = slot - (int32_t)input[(size_t)removed + 2];
                if (removed > current[reduced]) current[reduced] = removed;
            }
        }
        for (int32_t slot = 0; slot < 2 * width; ++slot) previous[slot] = current[slot];
    }

    const int32_t low_mass = target >= width ? target - width + 1 : 0;
    for (int32_t mass = target; mass >= low_mass; --mass) {
        if (previous[mass + width - target - 1] >= 0) return mass;
    }
    return 0;
}
