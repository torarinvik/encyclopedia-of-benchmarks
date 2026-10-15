#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 1024
#define TABLE_SIZE 2048

int64_t find_all_duplicates_hash_order(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (length > MAX_INPUT_LENGTH || (length > 0 && input == NULL)) return -1;
    int64_t keys[TABLE_SIZE] = {0}, counts[TABLE_SIZE] = {0};
    uint8_t used[TABLE_SIZE] = {0};
    size_t insertion_order[MAX_INPUT_LENGTH];
    size_t unique_count = 0;
    for (size_t i = 0; i < length; ++i) {
        int64_t remainder = input[i] % TABLE_SIZE;
        if (remainder < 0) remainder += TABLE_SIZE;
        size_t slot = (size_t)remainder;
        while (used[slot] && keys[slot] != input[i]) slot = (slot + 1) & (TABLE_SIZE - 1);
        if (!used[slot]) {
            used[slot] = 1; keys[slot] = input[i]; counts[slot] = 1;
            insertion_order[unique_count++] = slot;
        } else {
            counts[slot] += 1;
        }
    }
    size_t duplicate_count = 0;
    for (size_t i = 0; i < unique_count; ++i) if (counts[insertion_order[i]] > 1) ++duplicate_count;
    size_t required = duplicate_count * sizeof(int64_t);
    if (capacity < required || (required > 0 && output == NULL)) return -2;
    size_t out = 0;
    for (size_t i = 0; i < unique_count; ++i) {
        size_t slot = insertion_order[i];
        if (counts[slot] <= 1) continue;
        uint64_t bits = (uint64_t)keys[slot];
        for (size_t byte = 0; byte < 8; ++byte) output[out++] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)duplicate_count;
}
