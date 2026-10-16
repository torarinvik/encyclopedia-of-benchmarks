/* Portable greedy bandwidth allocation matching the pinned Java routine. */
#include <stddef.h>
#include <stdint.h>

#define MAX_USERS 64

typedef struct {
    double ratio;
    size_t index;
} allocation_item;

int64_t bandwidth_allocation(const int64_t *input, size_t length) {
    if (input == NULL || length < 2) return -1;
    int64_t bandwidth = input[0], count_value = input[1];
    if (bandwidth < 0 || bandwidth > 100000 || count_value < 0 || count_value > MAX_USERS)
        return -1;
    size_t count = (size_t)count_value;
    if (length != 2 + 2 * count) return -1;
    for (size_t index = 0; index < count; ++index) {
        int64_t demand = input[2 + index], value = input[2 + count + index];
        if (demand < 1 || demand > 1000 || value < 0 || value > 10000) return -1;
    }

    allocation_item items[MAX_USERS];
    for (size_t index = 0; index < count; ++index) {
        int64_t demand = input[2 + index], value = input[2 + count + index];
        items[index] = (allocation_item){(double)value / (double)demand, index};
    }
    /* Stable descending sort, matching Arrays.sort's stable object ordering. */
    for (size_t index = 1; index < count; ++index) {
        allocation_item key = items[index];
        size_t position = index;
        while (position > 0 && items[position - 1].ratio < key.ratio) {
            items[position] = items[position - 1];
            --position;
        }
        items[position] = key;
    }

    int64_t remaining = bandwidth, total = 0;
    for (size_t position = 0; position < count; ++position) {
        size_t index = items[position].index;
        int64_t demand = input[2 + index], value = input[2 + count + index];
        if (remaining >= demand) {
            total += value;
            remaining -= demand;
        } else {
            total += (int64_t)(items[position].ratio * (double)remaining);
            break;
        }
    }
    return total;
}
