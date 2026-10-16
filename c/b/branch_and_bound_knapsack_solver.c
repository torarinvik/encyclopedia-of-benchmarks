/* Breadth-first branch-and-bound for bounded 0/1 knapsack. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 8
#define MAX_NODES 511
#define MAX_ITEM_WEIGHT 1000
#define MAX_ITEM_VALUE 1000

typedef struct {
    int32_t level;
    int32_t weight;
    int32_t value;
    int32_t mask;
} search_node;

static double upper_bound(const int32_t *weights, const int32_t *item_values,
                          int32_t count, int32_t capacity,
                          int32_t level, int32_t weight, int32_t value)
{
    int32_t available = capacity - weight;
    double bound = (double)value;
    int32_t next = level + 1;
    while (available > 0 && next < count) {
        if (weights[next] <= available) {
            bound += item_values[next];
            available -= weights[next];
        } else {
            bound += ((double)item_values[next] / (double)weights[next]) * (double)available;
            available = 0;
        }
        ++next;
    }
    return bound;
}

int64_t branch_and_bound_knapsack_solver(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > 18) return -1;
    if (input[0] < 0 || input[0] > MAX_ITEMS || input[1] < 0 || input[1] > 8000) return -1;
    const int32_t count = (int32_t)input[0];
    const int32_t capacity = (int32_t)input[1];
    if (length != 2u + 2u * (size_t)count) return -1;

    int32_t weights[MAX_ITEMS] = {0}, item_values[MAX_ITEMS] = {0}, item_ids[MAX_ITEMS] = {0};
    for (int32_t index = 0; index < count; ++index) {
        const int64_t weight = input[2 + 2 * index];
        const int64_t value = input[3 + 2 * index];
        if (weight < 1 || weight > MAX_ITEM_WEIGHT || value < 1 || value > MAX_ITEM_VALUE) return -1;
        int32_t position = index;
        while (position > 0
               && value * (int64_t)weights[position - 1] > (int64_t)item_values[position - 1] * weight) {
            weights[position] = weights[position - 1];
            item_values[position] = item_values[position - 1];
            item_ids[position] = item_ids[position - 1];
            --position;
        }
        weights[position] = (int32_t)weight;
        item_values[position] = (int32_t)value;
        item_ids[position] = index;
    }

    search_node queue[MAX_NODES];
    size_t head = 0, tail = 1;
    queue[0] = (search_node){-1, 0, 0, 0};
    int32_t best_value = 0, best_mask = 0;
    while (head < tail) {
        const search_node parent = queue[head++];
        if (parent.level == count - 1) continue;
        const int32_t next = parent.level + 1;

        search_node left = {next, parent.weight + weights[next],
                            parent.value + item_values[next],
                            parent.mask | (1 << next)};
        search_node right = {next, parent.weight, parent.value, parent.mask};
        if (left.weight <= capacity && left.value > best_value) {
            best_value = left.value;
            best_mask = left.mask;
        }
        if (upper_bound(weights, item_values, count, capacity,
                        left.level, left.weight, left.value) > (double)best_value
            && left.weight < capacity) queue[tail++] = left;
        if (upper_bound(weights, item_values, count, capacity,
                        right.level, right.weight, right.value) > (double)best_value)
            queue[tail++] = right;
    }

    uint8_t selected[MAX_ITEMS];
    size_t selected_count = 0;
    for (int32_t level = count - 1; level >= 0; --level)
        if ((best_mask & (1 << level)) != 0) selected[selected_count++] = (uint8_t)item_ids[level];
    if (selected_count > output_capacity || (selected_count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < selected_count; ++index) output[index] = selected[index];
    return (int64_t)selected_count;
}
