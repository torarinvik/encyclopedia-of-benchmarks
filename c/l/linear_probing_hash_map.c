#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 32
#define MAX_CAPACITY 128
#define MAX_INPUT_LENGTH 98
#define MAX_OUTPUT_WORDS 320

typedef struct {
    int32_t keys[MAX_CAPACITY];
    int32_t values[MAX_CAPACITY];
    bool occupied[MAX_CAPACITY];
    size_t capacity;
    size_t size;
} hash_map;

static size_t hash_index(int32_t key, size_t capacity) {
    return ((uint32_t)key & UINT32_C(0x7fffffff)) % capacity;
}

static void resize_map(hash_map *map, size_t new_capacity) {
    int32_t old_keys[MAX_CAPACITY], old_values[MAX_CAPACITY];
    bool old_occupied[MAX_CAPACITY];
    const size_t old_capacity = map->capacity;
    for (size_t i = 0; i < old_capacity; ++i) {
        old_keys[i] = map->keys[i];
        old_values[i] = map->values[i];
        old_occupied[i] = map->occupied[i];
    }
    map->capacity = new_capacity;
    for (size_t i = 0; i < new_capacity; ++i) map->occupied[i] = false;
    for (size_t i = 0; i < old_capacity; ++i) {
        if (!old_occupied[i]) continue;
        size_t index = hash_index(old_keys[i], new_capacity);
        while (map->occupied[index]) index = (index + 1) % new_capacity;
        map->keys[index] = old_keys[i];
        map->values[index] = old_values[i];
        map->occupied[index] = true;
    }
}

static size_t find_slot(const hash_map *map, int32_t key) {
    size_t index = hash_index(key, map->capacity);
    for (size_t probes = 0; probes < map->capacity; ++probes) {
        if (!map->occupied[index]) return map->capacity;
        if (map->keys[index] == key) return index;
        index = (index + 1) % map->capacity;
    }
    return map->capacity;
}

static void put(hash_map *map, int32_t key, int32_t value) {
    if (map->size > map->capacity / 2) resize_map(map, map->capacity * 2);
    size_t index = hash_index(key, map->capacity);
    while (map->occupied[index]) {
        if (map->keys[index] == key) {
            map->values[index] = value;
            return;
        }
        index = (index + 1) % map->capacity;
    }
    map->keys[index] = key;
    map->values[index] = value;
    map->occupied[index] = true;
    ++map->size;
}

static bool delete_key(hash_map *map, int32_t key) {
    size_t index = find_slot(map, key);
    if (index == map->capacity) return false;
    map->occupied[index] = false;
    map->values[index] = 0;
    index = (index + 1) % map->capacity;
    while (map->occupied[index]) {
        const int32_t rehash_key = map->keys[index];
        const int32_t rehash_value = map->values[index];
        map->occupied[index] = false;
        map->values[index] = 0;
        --map->size;
        put(map, rehash_key, rehash_value);
        index = (index + 1) % map->capacity;
    }
    --map->size;
    if (map->size > 0 && map->size <= map->capacity / 8)
        resize_map(map, map->capacity / 2);
    return true;
}

static void append_word(int64_t *words, size_t *count, int64_t value) {
    words[(*count)++] = value;
}

int64_t linear_probing_hash_map(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 4 || input[0] > 16 || input[1] < 0 || input[1] > MAX_OPERATIONS) return -1;
    if (length > 2 + 3 * (size_t)input[1]) return -1;
    hash_map map = {0};
    map.capacity = (size_t)input[0];
    int64_t words[MAX_OUTPUT_WORDS];
    size_t word_count = 0, pos = 2;
    for (size_t opi = 0; opi < (size_t)input[1]; ++opi) {
        if (pos >= length) return -1;
        const int64_t opcode = input[pos++];
        if (opcode == 0) {
            if (pos + 1 >= length) return -1;
            const int64_t key64 = input[pos], value64 = input[pos + 1];
            pos += 2;
            if (key64 < INT32_MIN || key64 > INT32_MAX || value64 < INT32_MIN || value64 > INT32_MAX) return -1;
            put(&map, (int32_t)key64, (int32_t)value64);
            append_word(words, &word_count, 0);
            append_word(words, &word_count, 1);
        } else if (opcode >= 1 && opcode <= 3) {
            if (pos >= length) return -1;
            const int64_t key64 = input[pos++];
            if (key64 < INT32_MIN || key64 > INT32_MAX) return -1;
            const int32_t key = (int32_t)key64;
            const size_t index = find_slot(&map, key);
            if (opcode == 1) {
                append_word(words, &word_count, 1);
                if (index == map.capacity) {
                    append_word(words, &word_count, 1);
                    append_word(words, &word_count, 0);
                } else {
                    append_word(words, &word_count, 0);
                    append_word(words, &word_count, map.values[index]);
                }
            } else if (opcode == 2) {
                append_word(words, &word_count, 2);
                append_word(words, &word_count, delete_key(&map, key));
            } else {
                append_word(words, &word_count, 3);
                append_word(words, &word_count, index != map.capacity);
            }
        } else if (opcode == 4) {
            append_word(words, &word_count, 4);
            append_word(words, &word_count, (int64_t)map.size);
        } else if (opcode == 5) {
            int32_t sorted[MAX_OPERATIONS];
            size_t count = 0;
            for (size_t i = 0; i < map.capacity; ++i)
                if (map.occupied[i]) sorted[count++] = map.keys[i];
            for (size_t i = 1; i < count; ++i) {
                const int32_t value = sorted[i];
                size_t j = i;
                while (j > 0 && sorted[j - 1] > value) { sorted[j] = sorted[j - 1]; --j; }
                sorted[j] = value;
            }
            append_word(words, &word_count, 5);
            append_word(words, &word_count, (int64_t)count);
            for (size_t i = 0; i < count; ++i) append_word(words, &word_count, sorted[i]);
        } else return -1;
    }
    if (pos != length || word_count > MAX_OUTPUT_WORDS) return -1;
    const size_t bytes = word_count * 8;
    if (output == NULL || output_capacity < bytes) return -2;
    for (size_t i = 0; i < word_count; ++i) {
        const uint64_t bits = (uint64_t)words[i];
        for (size_t b = 0; b < 8; ++b) output[8 * i + b] = (uint8_t)(bits >> (8 * b));
    }
    return (int64_t)bytes;
}
