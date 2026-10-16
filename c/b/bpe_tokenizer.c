/* Apply bounded byte-pair merges with first-seen tie-breaking. */
#include <stddef.h>
#include <stdint.h>

int64_t bpe_tokenizer(const int64_t *values, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2 || length > 515) return -2;
    const int64_t merge_count_value = values[0];
    const int64_t byte_count_value = values[1];
    if (merge_count_value < 0 || merge_count_value > 32
        || byte_count_value < 0 || byte_count_value > 512
        || length != (size_t)byte_count_value + 2) return -2;

    int64_t tokens[512] = {0};
    int64_t next_tokens[512] = {0};
    const size_t byte_count = (size_t)byte_count_value;
    for (size_t index = 0; index < byte_count; ++index) {
        if (values[index + 2] < 0 || values[index + 2] > 255) return -2;
        tokens[index] = values[index + 2];
    }

    size_t token_count = byte_count;
    for (size_t step = 0; step < (size_t)merge_count_value && token_count > 1; ++step) {
        int64_t pair_left[511] = {0};
        int64_t pair_right[511] = {0};
        int64_t pair_frequency[511] = {0};
        size_t unique_pairs = 0;
        for (size_t index = 0; index + 1 < token_count; ++index) {
            size_t pair_index = 0;
            while (pair_index < unique_pairs
                   && (pair_left[pair_index] != tokens[index]
                       || pair_right[pair_index] != tokens[index + 1])) ++pair_index;
            if (pair_index == unique_pairs) {
                pair_left[pair_index] = tokens[index];
                pair_right[pair_index] = tokens[index + 1];
                pair_frequency[pair_index] = 1;
                ++unique_pairs;
            } else {
                ++pair_frequency[pair_index];
            }
        }
        if (unique_pairs == 0) break;
        size_t best = 0;
        for (size_t index = 1; index < unique_pairs; ++index) {
            if (pair_frequency[index] > pair_frequency[best]) best = index;
        }
        if (pair_frequency[best] == 1) break;

        size_t next_count = 0;
        size_t index = 0;
        while (index < token_count) {
            if (index + 1 < token_count && tokens[index] == pair_left[best]
                && tokens[index + 1] == pair_right[best]) {
                next_tokens[next_count++] = 256 + (int64_t)step;
                index += 2;
            } else {
                next_tokens[next_count++] = tokens[index++];
            }
        }
        for (size_t item = 0; item < next_count; ++item) tokens[item] = next_tokens[item];
        token_count = next_count;
    }

    if (token_count > output_capacity / 2 || (token_count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < token_count; ++index) {
        const uint16_t token = (uint16_t)tokens[index];
        output[2 * index] = (uint8_t)(token & 0xff);
        output[2 * index + 1] = (uint8_t)(token >> 8);
    }
    return (int64_t)token_count;
}
