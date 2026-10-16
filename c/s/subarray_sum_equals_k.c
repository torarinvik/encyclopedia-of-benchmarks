#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 512
#define TABLE_SIZE 2048

static size_t slot_for(int64_t value) {
    const int64_t magnitude = value < 0 ? -value : value;
    return (size_t)(magnitude % TABLE_SIZE);
}

int64_t subarray_sum_equals_k(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_ITEMS + 2) return INT64_MIN;
    const int64_t count_value = input[0];
    const int64_t target = input[1];
    if (count_value < 0 || count_value > MAX_ITEMS ||
        target < INT32_MIN || target > INT32_MAX) return INT64_MIN;
    const size_t count = (size_t)count_value;
    if (length != count + 2) return INT64_MIN;
    for (size_t index = 0; index < count; ++index) {
        if (input[index + 2] < INT32_MIN || input[index + 2] > INT32_MAX) return INT64_MIN;
    }

    int64_t keys[TABLE_SIZE] = {0};
    int64_t frequencies[TABLE_SIZE] = {0};
    keys[0] = 0;
    frequencies[0] = 1;
    int64_t prefix_sum = 0;
    int64_t result = 0;
    for (size_t index = 0; index < count; ++index) {
        prefix_sum += input[index + 2];
        const int64_t required = prefix_sum - target;
        size_t slot = slot_for(required);
        while (frequencies[slot] != 0 && keys[slot] != required) slot = (slot + 1) % TABLE_SIZE;
        result += frequencies[slot];

        slot = slot_for(prefix_sum);
        while (frequencies[slot] != 0 && keys[slot] != prefix_sum) slot = (slot + 1) % TABLE_SIZE;
        if (frequencies[slot] == 0) keys[slot] = prefix_sum;
        ++frequencies[slot];
    }
    return result;
}
