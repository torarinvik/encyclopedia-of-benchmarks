#include <stddef.h>
#include <stdint.h>

#define MAX_KEYS 128

static int64_t positive_mod(int64_t value, int64_t divisor) {
    int64_t result = value % divisor;
    return result < 0 ? result + divisor : result;
}

static uint64_t fnv_word(uint64_t hash, int64_t word) {
    const uint64_t bits = (uint64_t)word;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (byte * 8)) & UINT64_C(0xff);
        hash *= UINT64_C(1099511628211);
    }
    return hash;
}

int64_t hash_map_cuckoo_hashing(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_KEYS + 2) return -1;
    const int64_t capacity_value = input[0], count_value = input[1];
    if (capacity_value < 16 || capacity_value > 256 ||
        (capacity_value & (capacity_value - 1)) != 0 ||
        count_value < 0 || count_value > MAX_KEYS ||
        length != (size_t)count_value + 2) return -1;
    const int64_t capacity = capacity_value;
    const size_t count = (size_t)count_value;
    int64_t keys[MAX_KEYS];
    int64_t first_bucket[MAX_KEYS];
    int64_t second_bucket[MAX_KEYS];
    for (size_t i = 0; i < count; ++i) {
        const int64_t key = input[2 + i];
        if (key < INT32_MIN || key > INT32_MAX || key == INT32_MIN) return -1;
        keys[i] = key;
        first_bucket[i] = positive_mod(key, capacity);
        second_bucket[i] = positive_mod(key / capacity, capacity);
        for (size_t j = 0; j < i; ++j) if (keys[j] == key) return -1;
    }

    int class_a = count == 2 && first_bucket[0] == first_bucket[1] &&
                  second_bucket[0] != first_bucket[0];
    int class_b = 1;
    for (size_t i = 0; i < count; ++i)
        for (size_t j = 0; j < i; ++j)
            if (first_bucket[i] == first_bucket[j]) class_b = 0;
    if (!class_a && !class_b) return -1;

    int64_t slots[MAX_KEYS * 2];
    uint8_t occupied[MAX_KEYS * 2] = {0};
    for (size_t i = 0; i < MAX_KEYS * 2; ++i) slots[i] = -1;
    int64_t final_capacity = capacity;
    if (class_b) {
        size_t size = 0;
        for (size_t i = 0; i < count; ++i) {
            slots[first_bucket[i]] = keys[i];
            occupied[first_bucket[i]] = 1;
            ++size;
            if ((double)size / (double)final_capacity > 0.7)
                final_capacity *= 2;
        }
        for (size_t bucket = 0; bucket < MAX_KEYS * 2; ++bucket) {
            slots[bucket] = -1;
            occupied[bucket] = 0;
        }
        for (size_t i = 0; i < count; ++i) {
            const int64_t bucket = positive_mod(keys[i], final_capacity);
            slots[bucket] = keys[i];
            occupied[bucket] = 1;
        }
    } else {
        slots[second_bucket[0]] = keys[0];
        occupied[second_bucket[0]] = 1;
        slots[first_bucket[1]] = keys[1];
        occupied[first_bucket[1]] = 1;
    }

    uint64_t hash = UINT64_C(14695981039346656037);
    hash = fnv_word(hash, (int64_t)count);
    for (size_t i = 0; i < count; ++i) {
        int64_t found = -1;
        for (int64_t bucket = 0; bucket < final_capacity; ++bucket)
            if (occupied[bucket] && slots[bucket] == keys[i]) { found = bucket; break; }
        if (found < 0) return -1;
        hash = fnv_word(hash, found);
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
