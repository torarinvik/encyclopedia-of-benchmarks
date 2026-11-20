#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define NF_MAX_INDEX 17
#define NF_LIMIT 1000

static size_t nf_encode(int64_t value, uint8_t output[NF_MAX_INDEX]) {
    int64_t fib[NF_MAX_INDEX + 1] = {0};
    int64_t weight[NF_MAX_INDEX + 1] = {0};
    int64_t low[NF_MAX_INDEX + 1] = {0};
    int64_t high[NF_MAX_INDEX + 1] = {0};
    uint8_t digit[NF_MAX_INDEX + 1] = {0};
    fib[1] = 1;
    fib[2] = 1;
    for (size_t index = 3; index <= NF_MAX_INDEX; ++index)
        fib[index] = fib[index - 1] + fib[index - 2];
    for (size_t index = 1; index <= NF_MAX_INDEX; ++index)
        weight[index] = index & 1 ? fib[index] : -fib[index];
    for (size_t index = 1; index <= NF_MAX_INDEX; ++index) {
        const int64_t suffix_low = index == 1 ? 0 : low[index - 2];
        const int64_t suffix_high = index == 1 ? 0 : high[index - 2];
        const int64_t with_top_low = weight[index] + suffix_low;
        const int64_t with_top_high = weight[index] + suffix_high;
        low[index] = low[index - 1] < with_top_low ? low[index - 1] : with_top_low;
        high[index] = high[index - 1] > with_top_high ? high[index - 1] : with_top_high;
    }
    int64_t remaining = value;
    bool selected_above = false;
    for (size_t index = NF_MAX_INDEX; index > 0; --index) {
        bool choose = false;
        if (!selected_above) {
            const int64_t suffix_low = index == 1 ? 0 : low[index - 2];
            const int64_t suffix_high = index == 1 ? 0 : high[index - 2];
            const int64_t candidate = remaining - weight[index];
            choose = suffix_low <= candidate && candidate <= suffix_high;
        }
        if (choose) {
            digit[index] = 1;
            remaining -= weight[index];
        }
        selected_above = choose;
    }
    size_t highest = NF_MAX_INDEX;
    while (highest > 1 && digit[highest] == 0) --highest;
    for (size_t index = highest; index > 0; --index)
        output[highest - index] = (uint8_t)(digit[index] ? '1' : '0');
    return highest;
}

int64_t negafibonacci_representation(const int64_t *input, size_t length,
                                     uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1 || input[0] < -NF_LIMIT || input[0] > NF_LIMIT) return -1;
    uint8_t staged[NF_MAX_INDEX];
    const size_t required = nf_encode(input[0], staged);
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < required; ++index) output[index] = staged[index];
    return (int64_t)required;
}
