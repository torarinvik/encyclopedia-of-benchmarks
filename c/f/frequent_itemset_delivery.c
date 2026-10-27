#include <stddef.h>
#include <stdint.h>

enum { MAX_ITEMS = 8, MAX_ROWS = 64, MAX_INPUT = 69, MAX_OUTPUT = 200 };

static void put_u64(uint8_t *output, size_t word, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t frequent_itemset_delivery(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT) return -1;
    const int64_t item_count0 = input[0], row_count0 = input[1];
    const int64_t minimum = input[2], tail0 = input[3], prefix0 = input[4];
    if (item_count0 < 1 || item_count0 > MAX_ITEMS || row_count0 < 1 || row_count0 > MAX_ROWS ||
        minimum < 1 || minimum > row_count0 || length != 5 + (size_t)row_count0) return -1;
    const size_t item_count = (size_t)item_count0, row_count = (size_t)row_count0;
    if (tail0 < -1 || tail0 >= item_count0 || prefix0 < 0) return -1;
    const uint64_t item_limit = UINT64_C(1) << item_count;
    const uint64_t prefix = (uint64_t)prefix0;
    if (prefix >= item_limit) return -1;
    if ((tail0 == -1 && prefix != 0) ||
        (tail0 >= 0 && (((prefix >> (size_t)tail0) & 1) == 0 || (prefix >> ((size_t)tail0 + 1)) != 0))) return -1;

    uint64_t occurrences[MAX_ITEMS] = {0};
    uint64_t supports[MAX_ITEMS] = {0};
    for (size_t row = 0; row < row_count; ++row) {
        const int64_t row0 = input[5 + row];
        if (row0 < 0 || (uint64_t)row0 >= item_limit) return -1;
        const uint64_t mask = (uint64_t)row0;
        if ((mask & prefix) != prefix) continue;
        for (size_t item = (size_t)(tail0 + 1); item < item_count; ++item) {
            if ((mask & (UINT64_C(1) << item)) != 0) {
                occurrences[item] |= UINT64_C(1) << row;
                ++supports[item];
            }
        }
    }

    uint64_t words[1 + 3 * MAX_ITEMS] = {0};
    size_t records = 0;
    for (size_t item = (size_t)(tail0 + 1); item < item_count; ++item) {
        if (supports[item] < (uint64_t)minimum) continue;
        const size_t at = 1 + 3 * records++;
        words[at] = item;
        words[at + 1] = occurrences[item];
        words[at + 2] = supports[item];
    }
    words[0] = records;
    const size_t bytes = 8 * (1 + 3 * records);
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t word = 0; word < 1 + 3 * records; ++word) put_u64(output, word, words[word]);
    return (int64_t)bytes;
}
