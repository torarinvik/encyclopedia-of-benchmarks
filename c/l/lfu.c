/* Source-faithful bounded trace of the pinned Go LFU cache. */
#include <stddef.h>
#include <stdint.h>

#define MIN_CAPACITY 2
#define MAX_CAPACITY 16
#define MAX_OPERATIONS 32
#define MAX_INPUT_LENGTH (2 + 3 * MAX_OPERATIONS)
#define MAX_OUTPUT_WORDS (3 * MAX_OPERATIONS)

static void append_word(int64_t *words, size_t *count, int64_t value) {
    words[(*count)++] = value;
}

static void move_to_front(int32_t *keys, int32_t *values, size_t index) {
    const int32_t key = keys[index];
    const int32_t value = values[index];
    for (size_t i = index; i > 0; --i) {
        keys[i] = keys[i - 1];
        values[i] = values[i - 1];
    }
    keys[0] = key;
    values[0] = value;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t lfu(const int64_t *input, size_t length, uint8_t *output,
            size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < MIN_CAPACITY || input[0] > MAX_CAPACITY ||
        input[1] < 0 || input[1] > MAX_OPERATIONS) return -1;

    const size_t cache_capacity = (size_t)input[0];
    const size_t operation_count = (size_t)input[1];
    int32_t keys[MAX_CAPACITY] = {0};
    int32_t values[MAX_CAPACITY] = {0};
    size_t size = 0;
    int64_t words[MAX_OUTPUT_WORDS];
    size_t word_count = 0;
    size_t position = 2;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        if (position >= length) return -1;
        const int64_t opcode = input[position++];
        if (opcode == 0) {
            if (position + 1 >= length) return -1;
            const int64_t key_arg = input[position++];
            const int64_t value_arg = input[position++];
            if (key_arg < INT32_MIN || key_arg > INT32_MAX ||
                value_arg < INT32_MIN || value_arg > INT32_MAX) return -1;
            const int32_t key = (int32_t)key_arg;
            size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            if (index < size) {
                /* The pinned Put mutates a copied item; the old value remains. */
                move_to_front(keys, values, index);
            } else {
                if (size == cache_capacity) --size;
                for (size_t i = size; i > 0; --i) {
                    keys[i] = keys[i - 1];
                    values[i] = values[i - 1];
                }
                keys[0] = key;
                values[0] = (int32_t)value_arg;
                ++size;
            }
            append_word(words, &word_count, 0);
        } else if (opcode == 1) {
            if (position >= length) return -1;
            const int64_t key_arg = input[position++];
            if (key_arg < INT32_MIN || key_arg > INT32_MAX) return -1;
            const int32_t key = (int32_t)key_arg;
            size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            append_word(words, &word_count, 1);
            if (index == size) {
                append_word(words, &word_count, 1);
                append_word(words, &word_count, 0);
            } else {
                const int32_t value = values[index];
                move_to_front(keys, values, index);
                append_word(words, &word_count, 0);
                append_word(words, &word_count, value);
            }
        } else {
            return -1;
        }
    }
    if (position != length || word_count > MAX_OUTPUT_WORDS) return -1;

    const size_t output_length = word_count * 8;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t i = 0; i < word_count; ++i)
        put_i64_le(output, i * 8, words[i]);
    return (int64_t)output_length;
}
