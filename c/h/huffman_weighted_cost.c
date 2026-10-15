#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SYMBOLS 26
#define MAX_TOTAL_FREQUENCY INT64_C(2147483647)

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t huffman_weighted_cost(const int64_t *values, size_t length,
                              uint8_t *output, size_t capacity) {
    if (values == NULL || length < 1 || length > 1 + 2 * MAX_SYMBOLS) return -1;
    const int64_t raw_count = values[0];
    if (raw_count < 2 || raw_count > MAX_SYMBOLS || length != 1 + 2 * (size_t)raw_count) return -1;

    const size_t count = (size_t)raw_count;
    bool seen[MAX_SYMBOLS] = {false};
    bool active[MAX_SYMBOLS] = {false};
    int64_t weights[MAX_SYMBOLS];
    int64_t total = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t symbol = values[1 + 2 * index];
        const int64_t frequency = values[2 + 2 * index];
        if (symbol < 'a' || symbol > 'z' || frequency < 1 || frequency > MAX_TOTAL_FREQUENCY) return -1;
        const size_t letter = (size_t)(symbol - 'a');
        if (seen[letter] || total > MAX_TOTAL_FREQUENCY - frequency) return -1;
        seen[letter] = true;
        active[index] = true;
        weights[index] = frequency;
        total += frequency;
    }

    size_t remaining = count;
    int64_t cost = 0;
    while (remaining > 1) {
        size_t first = MAX_SYMBOLS, second = MAX_SYMBOLS;
        for (size_t index = 0; index < count; ++index) {
            if (!active[index]) continue;
            if (first == MAX_SYMBOLS || weights[index] < weights[first]) {
                second = first;
                first = index;
            } else if (second == MAX_SYMBOLS || weights[index] < weights[second]) {
                second = index;
            }
        }
        weights[first] += weights[second];
        active[second] = false;
        cost += weights[first];
        --remaining;
    }

    if (output == NULL || capacity < 8) return -2;
    store_i64_le(output, cost);
    return cost;
}
