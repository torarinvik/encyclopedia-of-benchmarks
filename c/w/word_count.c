/* Count literal-space-delimited words and matches for one requested word. */
#include <stddef.h>
#include <stdint.h>

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t word_count(const int64_t *values, size_t length,
                   uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 1050) return -1;
    const int64_t text_length_value = values[0];
    if (text_length_value < 0 || text_length_value > 999) return -1;
    const size_t text_length = (size_t)text_length_value;
    const size_t query_length_index = 1 + text_length;
    if (query_length_index >= length) return -1;
    const int64_t query_length_value = values[query_length_index];
    if (query_length_value < 0 || query_length_value > 49 ||
        length != query_length_index + 1 + (size_t)query_length_value) return -1;
    const size_t query_length = (size_t)query_length_value;
    for (size_t i = 1; i < query_length_index; ++i) if (values[i] < 1 || values[i] > 127) return -1;
    for (size_t i = query_length_index + 1; i < length; ++i) if (values[i] < 1 || values[i] > 127) return -1;
    size_t total = 0, matches = 0, start = 0;
    for (size_t end = 0; end <= text_length; ++end) {
        if (end == text_length || values[1 + end] == 32) {
            const size_t token_length = end - start;
            if (token_length > 49) return -1;
            if (total >= 20) return -2;
            if (token_length == query_length) {
                size_t offset = 0;
                while (offset < token_length && values[1 + start + offset] == values[query_length_index + 1 + offset]) ++offset;
                if (offset == token_length) ++matches;
            }
            ++total;
            start = end + 1;
        }
    }
    if (output == NULL || output_capacity < 16) return -2;
    store_i64_le(output, 0, (int64_t)total);
    store_i64_le(output, 8, (int64_t)matches);
    return 16;
}
