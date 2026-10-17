#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL_CAPACITY 16
#define MAX_TABLE_CAPACITY 128
#define MAX_OPERATIONS 32
#define MAX_INPUT_LENGTH 66
#define MAX_OUTPUT_WORDS 1088
#define MAX_KEY (INT32_MAX - 127)

static int32_t find_slot(const int32_t *table, size_t capacity, int32_t key) {
    size_t index = (size_t)key % capacity;
    for (size_t probes = 0; probes < capacity; ++probes) {
        if (table[index] == 0) return -1;
        if (table[index] == key) return (int32_t)index;
        index = (index + 1) % capacity;
    }
    return -1;
}

static int32_t insertion_slot(const int32_t *table, size_t capacity, int32_t key) {
    size_t index = (size_t)key % capacity;
    for (size_t probes = 0; probes < capacity; ++probes) {
        if (table[index] == 0 || table[index] == -1) return (int32_t)index;
        index = (index + 1) % capacity;
    }
    return -1;
}

static void rehash(int32_t *table, size_t *capacity) {
    int32_t old_table[MAX_TABLE_CAPACITY];
    const size_t old_capacity = *capacity;
    for (size_t i = 0; i < old_capacity; ++i) old_table[i] = table[i];
    *capacity *= 2;
    for (size_t i = 0; i < *capacity; ++i) table[i] = 0;
    for (size_t i = 0; i < old_capacity; ++i) {
        const int32_t key = old_table[i];
        if (key <= 0) continue;
        const int32_t slot = insertion_slot(table, *capacity, key);
        if (slot >= 0) table[slot] = key;
    }
}

int64_t linear_probing_hash_table(const int64_t *input, size_t length,
                                  uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > MAX_INITIAL_CAPACITY ||
        input[1] < 0 || input[1] > MAX_OPERATIONS) return -1;
    size_t table_capacity = (size_t)input[0];
    const size_t operation_count = (size_t)input[1];
    int32_t table[MAX_TABLE_CAPACITY] = {0};
    size_t size = 0, position = 2, word_count = 0;
    int64_t words[MAX_OUTPUT_WORDS];

    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const int64_t opcode = input[position++];
        if (opcode >= 0 && opcode <= 3) {
            if (position >= length) return -1;
            const int64_t key_arg = input[position++];
            if (key_arg < 1 || key_arg > MAX_KEY) return -1;
            const int32_t key = (int32_t)key_arg;
            if (opcode == 0) {
                const int32_t slot = insertion_slot(table, table_capacity, key);
                if (slot < 0) return -1;
                table[slot] = key;
                ++size;
                words[word_count++] = 0; words[word_count++] = 1;
                if (size * 2 >= table_capacity) rehash(table, &table_capacity);
            } else if (opcode == 1) {
                const int32_t slot = find_slot(table, table_capacity, key);
                if (slot < 0) return -1;
                table[slot] = -1;
                --size;
                words[word_count++] = 1; words[word_count++] = 1;
            } else if (opcode == 2) {
                words[word_count++] = 2;
                words[word_count++] = find_slot(table, table_capacity, key) >= 0 ? 1 : 0;
            } else {
                words[word_count++] = 3; words[word_count++] = key;
            }
        } else if (opcode == 4) {
            words[word_count++] = 4; words[word_count++] = (int64_t)table_capacity;
            for (size_t i = 0; i < table_capacity; ++i)
                words[word_count++] = table[i] == 0 ? -2 : table[i];
        } else return -1;
    }
    if (position != length || word_count > MAX_OUTPUT_WORDS) return -1;
    const size_t output_length = word_count * 8;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t i = 0; i < word_count; ++i) {
        const uint64_t bits = (uint64_t)words[i];
        for (size_t byte = 0; byte < 8; ++byte)
            output[8 * i + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)output_length;
}
