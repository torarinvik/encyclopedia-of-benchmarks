/* Compress a bounded printable-ASCII string using LZ78 phrase tokens. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64
#define MAX_PARSEABLE_INPUT_LENGTH 66
#define MAX_NODES (MAX_INPUT_LENGTH + 1)
#define ALPHABET_SIZE 95
#define MAX_OUTPUT_BYTES (16 * MAX_INPUT_LENGTH)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t lz78_compress(const int64_t *input, size_t input_length,
                      uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_INPUT_LENGTH) return -1;
    const size_t character_count = (size_t)input[0];
    if (input_length != 1 + character_count) return -1;
    for (size_t index = 0; index < character_count; ++index) {
        const int64_t character = input[index + 1];
        if (character < 32 || character > 126) return -1;
    }

    /* Child id 0 means absent; created nodes and phrase indices start at 1. */
    size_t children[MAX_NODES][ALPHABET_SIZE] = {{0}};
    int64_t token_prefix[MAX_INPUT_LENGTH];
    int64_t token_character[MAX_INPUT_LENGTH];
    size_t node_count = 1;
    size_t current_node = 0;
    size_t last_matched_index = 0;
    size_t token_count = 0;

    for (size_t index = 0; index < character_count; ++index) {
        const int64_t character = input[index + 1];
        const size_t edge = (size_t)(character - 32);
        const size_t child = children[current_node][edge];
        if (child != 0) {
            current_node = child;
            last_matched_index = child;
        } else {
            token_prefix[token_count] = (int64_t)last_matched_index;
            token_character[token_count] = character;
            ++token_count;
            children[current_node][edge] = node_count++;
            current_node = 0;
            last_matched_index = 0;
        }
    }

    if (current_node != 0) {
        token_prefix[token_count] = (int64_t)last_matched_index;
        token_character[token_count] = 0;
        ++token_count;
    }

    const size_t output_bytes = 16 * token_count;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t token = 0; token < token_count; ++token) {
        store_i64_le(output, 16 * token, token_prefix[token]);
        store_i64_le(output, 16 * token + 8, token_character[token]);
    }
    return (int64_t)output_bytes;
}
