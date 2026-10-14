/* Greedy fractional knapsack with exact fixed-point output. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_VALUES 258
#define MAX_ITEMS 128
#define LIMIT INT64_C(1000000)
#define SCALE INT64_C(1000000)

typedef struct {
    int64_t weight;
    int64_t value;
} item_t;

int64_t fractional_knapsack_benchmark(const int64_t *values, size_t length)
{
    if (length < 2 || length > MAX_INPUT_VALUES) return -1;
    const int64_t capacity = values[0];
    const int64_t item_count_value = values[1];
    if (capacity < 0 || capacity > LIMIT || item_count_value < 0 ||
        item_count_value > MAX_ITEMS) return -1;
    const size_t item_count = (size_t)item_count_value;
    if (length != 2 + 2 * item_count) return -1;

    item_t items[MAX_ITEMS];
    for (size_t i = 0; i < item_count; ++i) {
        const int64_t weight = values[2 + 2 * i];
        const int64_t value = values[3 + 2 * i];
        if (weight < 1 || weight > LIMIT || value < 0 || value > LIMIT) return -1;
        items[i] = (item_t){weight, value};
    }

    for (size_t i = 1; i < item_count; ++i) {
        const item_t current = items[i];
        size_t position = i;
        while (position > 0 &&
               items[position - 1].value * current.weight <
                   current.value * items[position - 1].weight) {
            items[position] = items[position - 1];
            --position;
        }
        items[position] = current;
    }

    int64_t remaining = capacity;
    int64_t scaled_value = 0;
    for (size_t i = 0; i < item_count && remaining > 0; ++i) {
        if (remaining >= items[i].weight) {
            scaled_value += items[i].value * SCALE;
            remaining -= items[i].weight;
        } else {
            scaled_value += items[i].value * remaining * SCALE / items[i].weight;
            break;
        }
    }
    return scaled_value;
}
