/* Bounded source-faithful trace of the pinned Java PN counter. */
#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 16
#define COUNTER_COUNT 3
#define MAX_OPERATIONS 64
#define MAX_INPUT_LENGTH (5 + MAX_OPERATIONS)
#define MAX_OUTPUT_WORDS (2 * MAX_OPERATIONS)

static const size_t merge_pairs[6][2] = {
    {0, 1}, {0, 2}, {1, 0}, {1, 2}, {2, 0}, {2, 1}
};

static void append_word(int64_t *words, size_t *count, int64_t value) {
    words[(*count)++] = value;
}

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t pncounter(const int64_t *input, size_t length, uint8_t *output,
                  size_t output_capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_NODES ||
        input[4] < 0 || input[4] > MAX_OPERATIONS) return -1;

    const size_t node_count = (size_t)input[0];
    size_t ids[COUNTER_COUNT];
    for (size_t counter = 0; counter < COUNTER_COUNT; ++counter) {
        if (input[1 + counter] < 0 || input[1 + counter] >= input[0]) return -1;
        ids[counter] = (size_t)input[1 + counter];
    }
    const size_t operation_count = (size_t)input[4];
    if (length != 5 + operation_count) return -1;

    int64_t positive[COUNTER_COUNT][MAX_NODES] = {{0}};
    int64_t negative[COUNTER_COUNT][MAX_NODES] = {{0}};
    int64_t words[MAX_OUTPUT_WORDS];
    size_t word_count = 0;
    size_t position = 5;

    for (size_t operation = 0; operation < operation_count; ++operation) {
        const int64_t opcode = input[position++];
        if (opcode < 0 || opcode > 20) return -1;
        if (opcode < 6) {
            const size_t counter = (size_t)(opcode / 2);
            if ((opcode & 1) == 0) ++positive[counter][ids[counter]];
            else ++negative[counter][ids[counter]];
            append_word(words, &word_count, opcode);
        } else if (opcode < 9) {
            const size_t counter = (size_t)(opcode - 6);
            int64_t value = 0;
            for (size_t node = 0; node < node_count; ++node)
                value += positive[counter][node] - negative[counter][node];
            append_word(words, &word_count, opcode);
            append_word(words, &word_count, value);
        } else if (opcode < 15) {
            const size_t pair = (size_t)(opcode - 9);
            const size_t target = merge_pairs[pair][0];
            const size_t source = merge_pairs[pair][1];
            for (size_t node = 0; node < node_count; ++node) {
                if (positive[target][node] < positive[source][node])
                    positive[target][node] = positive[source][node];
                if (negative[target][node] < negative[source][node])
                    negative[target][node] = negative[source][node];
            }
            append_word(words, &word_count, opcode);
        } else {
            const size_t pair = (size_t)(opcode - 15);
            const size_t left = merge_pairs[pair][0];
            const size_t right = merge_pairs[pair][1];
            int64_t result = 1;
            for (size_t node = 0; node < node_count; ++node) {
                if (positive[left][node] > positive[right][node] &&
                    negative[left][node] > negative[right][node]) {
                    result = 0;
                    break;
                }
            }
            append_word(words, &word_count, opcode);
            append_word(words, &word_count, result);
        }
    }

    const size_t output_length = word_count * 8;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t i = 0; i < word_count; ++i)
        put_i64_le(output, i * 8, words[i]);
    return (int64_t)output_length;
}
