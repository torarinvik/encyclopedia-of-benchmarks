#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 8

int64_t greedy_item_selection_by_value(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > 2 + 2 * MAX_ITEMS) return -1;
    const int64_t capacity = values[0], count_value = values[1];
    if (capacity < 0 || capacity > 1000000 || count_value < 0 || count_value > MAX_ITEMS || length != 2 + 2 * (size_t)count_value) return -1;
    const int count = (int)count_value;
    int64_t item_values[MAX_ITEMS] = {0}, weights[MAX_ITEMS] = {0};
    int order[MAX_ITEMS] = {0};
    for (int index = 0; index < count; ++index) {
        item_values[index] = values[2 + (size_t)index];
        weights[index] = values[2 + (size_t)count + (size_t)index];
        if (item_values[index] < 0 || item_values[index] > 1000000 || weights[index] < 1 || weights[index] > 1000000) return -1;
        order[index] = index;
    }
    for (int index = 1; index < count; ++index) {
        const int current = order[index];
        int position = index;
        while (position > 0 && item_values[order[position - 1]] < item_values[current]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = current;
    }
    int64_t total_weight = 0, total_value = 0, sequence = 0;
    int selected = 0;
    for (int index = 0; index < count; ++index) {
        const int item = order[index];
        if (total_weight + weights[item] <= capacity) {
            sequence |= (int64_t)(item + 1) << (4 * selected);
            ++selected;
            total_weight += weights[item];
            total_value += item_values[item];
        }
    }
    return (total_value << 36) | ((int64_t)selected << 32) | sequence;
}
