#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 512
#define MAX_ENTRIES 128
#define MAX_KEY 99999
#define BUCKET_COUNT 16
#define MAX_INPUT_LENGTH (1 + 3 * MAX_OPERATIONS)
#define FNV_OFFSET UINT64_C(0xcbf29ce484222325)
#define FNV_PRIME UINT64_C(0x100000001b3)
#define RESULT_MASK UINT64_C(0x7fffffffffffffff)

static uint64_t hash_byte(uint64_t hash, uint8_t byte)
{
    return (hash ^ byte) * FNV_PRIME;
}

static uint64_t hash_i32(uint64_t hash, int64_t value)
{
    uint32_t bits = (uint32_t)value;
    for (unsigned shift = 0; shift < 32; shift += 8)
        hash = hash_byte(hash, (uint8_t)(bits >> shift));
    return hash;
}

static int find_entry(const int64_t *keys, const int *next, const int *buckets, int64_t key)
{
    for (int entry = buckets[key % BUCKET_COUNT]; entry >= 0; entry = next[entry])
        if (keys[entry] == key) return entry;
    return -1;
}

int64_t hash_map_separate_chaining(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > MAX_OPERATIONS ||
        length != 1 + 3 * (size_t)operation_count) return -1;

    int64_t keys[MAX_ENTRIES] = {0}, mapped_values[MAX_ENTRIES] = {0};
    int next[MAX_ENTRIES], buckets[BUCKET_COUNT], free_slots[MAX_ENTRIES];
    int free_count = MAX_ENTRIES, size = 0;
    for (int i = 0; i < MAX_ENTRIES; ++i) { next[i] = -1; free_slots[i] = i; }
    for (int i = 0; i < BUCKET_COUNT; ++i) buckets[i] = -1;
    uint64_t hash = FNV_OFFSET;

    for (int64_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = input[1 + 3 * operation];
        const int64_t key = input[2 + 3 * operation];
        const int64_t value = input[3 + 3 * operation];
        uint8_t result_code = 0;
        int64_t returned_value = 0;

        if (opcode == 0) {
            if (key < 0 || key > MAX_KEY || value < INT32_MIN || value > INT32_MAX) return -1;
            const int bucket = (int)(key % BUCKET_COUNT);
            int entry = find_entry(keys, next, buckets, key);
            if (entry >= 0) {
                mapped_values[entry] = value;
            } else {
                if (size >= MAX_ENTRIES) return -1;
                entry = free_slots[--free_count];
                keys[entry] = key;
                mapped_values[entry] = value;
                next[entry] = buckets[bucket];
                buckets[bucket] = entry;
                ++size;
            }
        } else if (opcode == 1) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            const int entry = find_entry(keys, next, buckets, key);
            if (entry >= 0) { result_code = 1; returned_value = mapped_values[entry]; }
        } else if (opcode == 2) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            const int bucket = (int)(key % BUCKET_COUNT);
            int previous = -1;
            int entry = buckets[bucket];
            while (entry >= 0) {
                const int following = next[entry];
                if (keys[entry] == key) {
                    if (previous < 0) buckets[bucket] = following;
                    else next[previous] = following;
                    free_slots[free_count++] = entry;
                    --size;
                    break;
                }
                previous = entry;
                entry = following;
            }
        } else if (opcode == 3) {
            if (key < 0 || key > MAX_KEY || value != 0) return -1;
            result_code = (uint8_t)(find_entry(keys, next, buckets, key) >= 0);
        } else if (opcode == 4) {
            if (key != 0 || value != 0) return -1;
            for (int i = 0; i < BUCKET_COUNT; ++i) buckets[i] = -1;
            for (int i = 0; i < MAX_ENTRIES; ++i) { next[i] = -1; free_slots[i] = i; }
            free_count = MAX_ENTRIES;
            size = 0;
        } else {
            return -1;
        }

        hash = hash_byte(hash, (uint8_t)opcode);
        hash = hash_byte(hash, result_code);
        if (opcode == 1 && result_code == 1) hash = hash_i32(hash, returned_value);
    }
    return (int64_t)(hash & RESULT_MASK);
}
