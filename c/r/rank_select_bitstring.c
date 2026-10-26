#include <stddef.h>
#include <stdint.h>

#define MAX_BITS 63
#define MAX_BLOCKS 8
#define MAX_QUERIES 16
#define MAX_INPUT 35
#define MAX_OUTPUT_BYTES 128

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t rank_select_bitstring(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0], packed_value = input[1], query_value = input[2];
    if (n_value < 1 || n_value > MAX_BITS || packed_value < 0 || query_value < 0 || query_value > MAX_QUERIES) return -1;
    size_t n = (size_t)n_value, queries = (size_t)query_value;
    uint64_t bits = (uint64_t)packed_value;
    if ((bits >> n) != 0 || length != 3 + 2 * queries) return -1;
    size_t block_count = (n + 7) / 8;
    int64_t prefix[MAX_BLOCKS + 1] = {0};
    for (size_t block = 0; block < block_count; ++block) {
        prefix[block + 1] = prefix[block];
        size_t end = 8 * block + 8 < n ? 8 * block + 8 : n;
        for (size_t pos = 8 * block; pos < end; ++pos) prefix[block + 1] += (int64_t)((bits >> pos) & 1U);
    }
    int64_t answers[MAX_QUERIES] = {0};
    for (size_t query = 0; query < queries; ++query) {
        int64_t op = input[3 + 2 * query], index_value = input[4 + 2 * query];
        if ((op != 0 && op != 1) || index_value < 1 ||
            (op == 0 ? index_value > n_value : index_value > MAX_BITS + 1)) return -1;
        size_t index = (size_t)index_value;
        if (op == 0) {
            size_t full_blocks = index / 8, remainder = index % 8;
            int64_t answer = prefix[full_blocks];
            for (size_t pos = 8 * full_blocks; pos < 8 * full_blocks + remainder; ++pos) answer += (int64_t)((bits >> pos) & 1U);
            answers[query] = answer;
        } else {
            size_t block = 0;
            while (block < block_count && prefix[block + 1] < index) ++block;
            answers[query] = -1;
            if (block < block_count) {
                size_t remaining = index - (size_t)prefix[block];
                size_t end = 8 * block + 8 < n ? 8 * block + 8 : n;
                for (size_t pos = 8 * block; pos < end; ++pos) {
                    if (((bits >> pos) & 1U) != 0 && --remaining == 0) { answers[query] = (int64_t)pos + 1; break; }
                }
            }
        }
    }
    size_t output_bytes = 8 * queries;
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t query = 0; query < queries; ++query) store_i64_le(staged, 8 * query, answers[query]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
