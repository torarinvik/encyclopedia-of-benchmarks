#include <stddef.h>
#include <stdint.h>

enum { MAX_ITEMS = 8, MAX_ROWS = 64, MAX_INPUT = 69, MAX_OUTPUT = 1032 };

static void put_u64(uint8_t *output, size_t word, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t frequent_itemset_conditional_db_reduction(const int64_t *input, size_t length,
                                                   uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], rows0 = input[1], minimum = input[2];
    const int64_t tail0 = input[3], prefix0 = input[4];
    if (n0 < 1 || n0 > MAX_ITEMS || rows0 < 1 || rows0 > MAX_ROWS ||
        minimum < 1 || minimum > rows0 || length != 5 + (size_t)rows0) return -1;
    const size_t n = (size_t)n0, rows = (size_t)rows0;
    if (tail0 < -1 || tail0 >= n0 || prefix0 < 0) return -1;
    const uint64_t limit = UINT64_C(1) << n, prefix = (uint64_t)prefix0;
    if (prefix >= limit || (tail0 == -1 && prefix != 0) ||
        (tail0 >= 0 && (((prefix >> (size_t)tail0) & 1) == 0 ||
                        (prefix >> ((size_t)tail0 + 1)) != 0))) return -1;

    uint64_t selected[MAX_ROWS] = {0};
    size_t selected_count = 0;
    uint64_t support[MAX_ITEMS] = {0};
    for (size_t row = 0; row < rows; ++row) {
        const int64_t row0 = input[5 + row];
        if (row0 < 0 || (uint64_t)row0 >= limit) return -1;
        const uint64_t mask = (uint64_t)row0;
        if ((mask & prefix) != prefix) continue;
        selected[selected_count++] = mask;
        for (size_t item = (size_t)(tail0 + 1); item < n; ++item)
            if ((mask & (UINT64_C(1) << item)) != 0) ++support[item];
    }
    if (selected_count < (size_t)minimum) return -1;

    uint64_t keep = tail0 >= 0 ? UINT64_C(1) << (size_t)tail0 : 0;
    for (size_t item = (size_t)(tail0 + 1); item < n; ++item)
        if (support[item] >= (uint64_t)minimum) keep |= UINT64_C(1) << item;
    const uint64_t below_tail = tail0 > 0 ? (UINT64_C(1) << (size_t)tail0) - 1 : 0;
    uint64_t masks[MAX_ROWS] = {0}, multiplicities[MAX_ROWS] = {0};
    size_t distinct = 0;
    for (size_t row = 0; row < selected_count; ++row) {
        const uint64_t reduced = selected[row] & ~below_tail & keep;
        size_t at = 0;
        while (at < distinct && masks[at] != reduced) ++at;
        if (at == distinct) masks[distinct++] = reduced;
        ++multiplicities[at];
    }
    for (size_t i = 1; i < distinct; ++i) {
        const uint64_t mask = masks[i], count = multiplicities[i];
        size_t j = i;
        while (j > 0 && masks[j - 1] > mask) {
            masks[j] = masks[j - 1]; multiplicities[j] = multiplicities[j - 1]; --j;
        }
        masks[j] = mask; multiplicities[j] = count;
    }
    const size_t word_count = 1 + 2 * distinct, bytes = 8 * word_count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == NULL || capacity < bytes) return -2;
    put_u64(output, 0, distinct);
    for (size_t i = 0; i < distinct; ++i) {
        put_u64(output, 1 + 2 * i, masks[i]);
        put_u64(output, 2 + 2 * i, multiplicities[i]);
    }
    return (int64_t)bytes;
}
