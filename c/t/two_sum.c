/* One-pass two-sum with portable open addressing and first-pair ordering. */
#include <stddef.h>
#include <stdint.h>

#define TWO_SUM_MAX_VALUES 256
#define TWO_SUM_TABLE_SIZE 512
#define TWO_SUM_INDEX_BASE 256

static size_t two_sum_hash_slot(int64_t key, size_t capacity)
{
    const int64_t prime = INT64_C(2147483647);
    int64_t normalized = key % prime;
    if (normalized < 0) normalized += prime;
    const int64_t mixed = (normalized * INT64_C(48271)) % prime;
    return (size_t)mixed % capacity;
}

int64_t two_sum(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > TWO_SUM_MAX_VALUES + 1) return -2;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < INT64_C(-2147483648) || values[index] > INT64_C(2147483647)) return -2;
    }
    const int64_t target = values[0];
    const size_t value_count = length - 1;
    size_t capacity = 1;
    while (capacity < value_count * 2) capacity *= 2;
    int64_t keys[TWO_SUM_TABLE_SIZE];
    size_t first_indices[TWO_SUM_TABLE_SIZE];
    uint8_t occupied[TWO_SUM_TABLE_SIZE] = {0};

    for (size_t index = 0; index < value_count; ++index) {
        const int64_t current = values[index + 1];
        const int64_t complement = target - current;
        size_t slot = two_sum_hash_slot(complement, capacity);
        while (occupied[slot] && keys[slot] != complement) slot = (slot + 1) % capacity;
        if (occupied[slot]) return (int64_t)(first_indices[slot] * TWO_SUM_INDEX_BASE + index);

        slot = two_sum_hash_slot(current, capacity);
        while (occupied[slot] && keys[slot] != current) slot = (slot + 1) % capacity;
        if (!occupied[slot]) {
            occupied[slot] = 1;
            keys[slot] = current;
            first_indices[slot] = index;
        }
    }
    return -1;
}
