#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT_LENGTH = 64, MAX_INPUT_LENGTH = 66, MAX_OUTPUT_BYTES = 1536 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t lz77_java_compress(const int64_t *input, size_t input_length,
                           uint8_t *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1u || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_TEXT_LENGTH) return -1;
    const size_t text_length = (size_t)input[0];
    if (input_length != 1u + text_length) return -1;
    for (size_t index = 0; index < text_length; ++index)
        if (input[index + 1u] < 32 || input[index + 1u] > 126) return -1;

    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    size_t token_count = 0;
    size_t current = 0;
    while (current < text_length) {
        size_t best_distance = 0;
        size_t best_length = 0;
        const size_t search_start = current > 4096u ? current - 4096u : 0u;
        const size_t lookahead_end = current + 16u < text_length ? current + 16u : text_length;
        for (size_t candidate = search_start; candidate < current; ++candidate) {
            size_t match_length = 0;
            while (current + match_length < lookahead_end) {
                size_t source = candidate + match_length;
                if (source >= current) {
                    const size_t distance = current - candidate;
                    source = candidate + (match_length % distance);
                }
                if (input[source + 1u] != input[current + match_length + 1u]) break;
                ++match_length;
            }
            if (match_length > best_length) {
                best_distance = current - candidate;
                best_length = match_length;
            }
        }

        const int64_t next_character = current + best_length < text_length
            ? input[current + best_length + 1u] : 0;
        const size_t byte_offset = token_count * 24u;
        store_i64_le(staged, byte_offset, (int64_t)best_distance);
        store_i64_le(staged, byte_offset + 8u, (int64_t)best_length);
        store_i64_le(staged, byte_offset + 16u, next_character);
        ++token_count;
        current += next_character == 0 ? best_length : best_length + 1u;
    }

    const size_t output_bytes = token_count * 24u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return (int64_t)output_bytes;
}
