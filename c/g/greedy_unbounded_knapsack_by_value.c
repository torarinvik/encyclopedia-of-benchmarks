#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 8

int64_t greedy_unbounded_knapsack_by_value(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > 2 + 2 * MAX_ITEMS) return -1;
    int64_t remaining = values[0], count_value = values[1];
    if (remaining < 0 || remaining > 1000000 || count_value < 0 || count_value > MAX_ITEMS ||
        length != 2 + 2 * (size_t)count_value) return -1;
    int count = (int)count_value;
    int64_t item_values[MAX_ITEMS] = {0}, weights[MAX_ITEMS] = {0}, total_value = 0;
    int order[MAX_ITEMS] = {0};
    for (int index = 0; index < count; ++index) {
        item_values[index] = values[2 + (size_t)index];
        weights[index] = values[2 + (size_t)count + (size_t)index];
        if (item_values[index] < 0 || item_values[index] > 1000000 || weights[index] < 1 || weights[index] > 1000000) return -1;
        order[index] = index;
    }
    for (int index = 1; index < count; ++index) {
        int current = order[index], position = index;
        while (position > 0 && item_values[order[position - 1]] < item_values[current]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }
    for (int index = 0; index < count; ++index) {
        int item = order[index];
        while (remaining >= weights[item]) {
            total_value += item_values[item];
            remaining -= weights[item];
        }
    }
    return total_value;
}
