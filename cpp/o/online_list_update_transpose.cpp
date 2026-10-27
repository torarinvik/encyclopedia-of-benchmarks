#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_REQUESTS = 32, MAX_INPUT = 42, MAX_OUTPUT_BYTES = 328 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t online_list_update_transpose(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0], requests_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N || requests_raw < 0 || requests_raw > MAX_REQUESTS) return -1;
    const size_t n = (size_t)n_raw, requests = (size_t)requests_raw;
    if (length != 2 + n + requests) return -1;
    int order[MAX_N]; uint8_t seen[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t item = input[2 + i];
        if (item < 0 || item >= n_raw || seen[(size_t)item]) return -1;
        order[i] = (int)item; seen[(size_t)item] = 1;
    }
    int64_t positions[MAX_REQUESTS] = {0}, total_cost = 0;
    for (size_t request = 0; request < requests; ++request) {
        const int64_t item_raw = input[2 + n + request];
        if (item_raw < 0 || item_raw >= n_raw) return -1;
        size_t position = 0;
        while (position < n && order[position] != (int)item_raw) ++position;
        if (position == n) return -1;
        positions[request] = (int64_t)(position + 1);
        total_cost += (int64_t)(position + 1);
        if (position > 0) { const int previous = order[position - 1]; order[position - 1] = order[position]; order[position] = previous; ++total_cost; }
    }
    int64_t words[1 + MAX_N + MAX_REQUESTS] = {0};
    words[0] = total_cost;
    for (size_t i = 0; i < n; ++i) words[1 + i] = order[i];
    for (size_t i = 0; i < requests; ++i) words[1 + n + i] = positions[i];
    const size_t output_bytes = 8 * (1 + n + requests);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t word = 0; word < 1 + n + requests; ++word) store_i64_le(staged, 8 * word, words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
