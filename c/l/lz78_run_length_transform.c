/* Clean-room bounded Kosaraju-Manzini LZ78RL profile. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 32
#define MAX_PARSEABLE_INPUT_LENGTH 34
#define MAX_TRIE_NODES (MAX_TEXT_LENGTH + 1)
#define MAX_TOKENS MAX_TEXT_LENGTH
#define MAX_OUTPUT_BYTES (8 + 24 * MAX_TOKENS)
#define ALPHABET_SIZE 4

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t lz78_run_length_transform(const int64_t *input, size_t input_length,
                                  uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT_LENGTH) return -1;
    const size_t n = (size_t)input[0];
    if (input_length != n + 1) return -1;
    for (size_t i = 0; i < n; ++i)
        if (input[i + 1] < 1 || input[i + 1] > 3) return -1;

    int64_t transformed[MAX_TEXT_LENGTH] = {0};
    size_t transformed_length = 0;
    size_t position = 0;
    while (position < n) {
        const int64_t symbol = input[position + 1];
        size_t end = position + 1;
        while (end < n && input[end + 1] == symbol) ++end;
        const size_t run_length = end - position;
        size_t highest_bit = 0;
        for (size_t value = run_length; value > 1; value >>= 1) ++highest_bit;
        for (size_t bit = highest_bit + 1; bit > 0; --bit) {
            const size_t shift = bit - 1;
            transformed[transformed_length++] = ((run_length >> shift) & 1) ? symbol : 0;
        }
        position = end;
    }

    size_t children[MAX_TRIE_NODES][ALPHABET_SIZE] = {{0}};
    int64_t tokens[MAX_TOKENS][3] = {{0}};
    size_t token_count = 0;
    size_t position_in_text = 0;
    size_t next_phrase_id = 1;
    while (position_in_text < transformed_length) {
        size_t node = 0;
        size_t end = position_in_text;
        while (end < transformed_length) {
            const size_t child = children[node][(size_t)transformed[end]];
            if (child == 0) break;
            node = child;
            ++end;
        }
        if (end == transformed_length) {
            if (node != 0) {
                tokens[token_count][0] = (int64_t)node;
                tokens[token_count][1] = 0;
                tokens[token_count][2] = 1;
                ++token_count;
            }
            break;
        }
        const size_t symbol = (size_t)transformed[end];
        tokens[token_count][0] = (int64_t)node;
        tokens[token_count][1] = (int64_t)symbol;
        tokens[token_count][2] = 0;
        ++token_count;
        children[node][symbol] = next_phrase_id++;
        position_in_text = end + 1;
    }

    const size_t output_bytes = 8 + 24 * token_count;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, (int64_t)token_count);
    for (size_t token = 0; token < token_count; ++token)
        for (size_t field = 0; field < 3; ++field)
            store_i64_le(staged, 8 + 24 * token + 8 * field, tokens[token][field]);
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
