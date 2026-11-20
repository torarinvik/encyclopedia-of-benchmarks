#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 16
#define MAX_CAPACITY 32
#define MAX_INPUT_LENGTH 19
#define DP_STRIDE (MAX_CAPACITY + 1)

int64_t subset_sum_bin_packing(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[0];
    const int64_t raw_capacity = input[1];
    if (raw_count < 1 || raw_count > MAX_ITEMS ||
        raw_capacity < 1 || raw_capacity > MAX_CAPACITY) return -1;
    const size_t count = (size_t)raw_count;
    const size_t capacity = (size_t)raw_capacity;
    if (length != 2 + count) return -1;

    int64_t remaining_size[MAX_ITEMS];
    size_t remaining_item[MAX_ITEMS];
    int64_t assigned_bin[MAX_ITEMS] = {0};
    for (size_t i = 0; i < count; ++i) {
        const int64_t size = input[2 + i];
        if (size < 1 || size > raw_capacity) return -1;
        remaining_size[i] = size;
        remaining_item[i] = i;
    }

    size_t remaining_count = count;
    int64_t bin_count = 0;
    while (remaining_count > 0) {
        uint8_t reachable[MAX_ITEMS + 1][DP_STRIDE] = {{0}};
        reachable[remaining_count][0] = 1;
        for (size_t i = remaining_count; i > 0; --i) {
            const size_t item = i - 1;
            const size_t size = (size_t)remaining_size[item];
            for (size_t sum = 0; sum <= capacity; ++sum) {
                reachable[item][sum] = reachable[item + 1][sum];
                if (sum >= size && reachable[item + 1][sum - size])
                    reachable[item][sum] = 1;
            }
        }

        size_t target = capacity;
        while (target > 0 && !reachable[0][target]) --target;
        uint8_t selected[MAX_ITEMS] = {0};
        size_t needed = target;
        for (size_t i = 0; i < remaining_count; ++i) {
            const size_t size = (size_t)remaining_size[i];
            if (size <= needed && reachable[i + 1][needed - size]) {
                selected[i] = 1;
                needed -= size;
                assigned_bin[remaining_item[i]] = bin_count;
            }
        }

        size_t survivors = 0;
        for (size_t i = 0; i < remaining_count; ++i) {
            if (!selected[i]) {
                remaining_size[survivors] = remaining_size[i];
                remaining_item[survivors] = remaining_item[i];
                ++survivors;
            }
        }
        remaining_count = survivors;
        ++bin_count;
    }

    int64_t checksum = bin_count * 10000;
    for (size_t i = 0; i < count; ++i)
        checksum += (int64_t)(i + 1) * (assigned_bin[i] + 1);
    return checksum;
}
