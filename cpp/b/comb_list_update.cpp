#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_REQUESTS = 32, MAX_INPUT = 82, MAX_OUTPUT_BYTES = 392 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t comb_list_update(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0], requests_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_N || requests_raw < 0 || requests_raw > MAX_REQUESTS) return -1;
    const size_t n = (size_t)n_raw, requests = (size_t)requests_raw;
    if (length != 2 + 2 * n + 2 * requests) return -1;
    int order[MAX_N], seen[MAX_N] = {0}, request_ids[MAX_REQUESTS], modes[MAX_REQUESTS], bits[MAX_N];
    for (size_t i = 0; i < n; ++i) { const int64_t page = input[2 + i]; if (page < 0 || page >= n_raw || seen[(size_t)page]) return -1; order[i] = (int)page; seen[(size_t)page] = 1; }
    for (size_t i = 0; i < requests; ++i) { const int64_t page = input[2 + n + i]; if (page < 0 || page >= n_raw) return -1; request_ids[i] = (int)page; }
    for (size_t i = 0; i < n; ++i) { const int64_t bit = input[2 + n + requests + i]; if (bit != 0 && bit != 1) return -1; bits[i] = (int)bit; }
    for (size_t i = 0; i < requests; ++i) { const int64_t mode = input[2 + 2 * n + requests + i]; if (mode < 0 || mode > 4) return -1; modes[i] = (int)mode; }
    int last_request[MAX_N]; for (size_t i = 0; i < n; ++i) last_request[i] = -1;
    int64_t positions[MAX_REQUESTS] = {0}, total_cost = 0;
    for (size_t time = 0; time < requests; ++time) {
        const int page = request_ids[time]; size_t position = 0;
        while (position < n && order[position] != page) ++position;
        if (position == n) return -1;
        positions[time] = (int64_t)(position + 1); total_cost += (int64_t)(position + 1);
        if (modes[time] < 4) {
            bits[page] ^= 1;
            if (bits[page] == 1 && position > 0) { for (size_t shift = position; shift > 0; --shift) order[shift] = order[shift - 1]; order[0] = page; }
        } else if (last_request[page] >= 0) {
            for (size_t target = 0; target < position; ++target) {
                const int candidate = order[target]; size_t occurrences = 0;
                for (size_t t = (size_t)(last_request[page] + 1); t < time; ++t) if (request_ids[t] == candidate) ++occurrences;
                if (occurrences <= 1) { for (size_t shift = position; shift > target; --shift) order[shift] = order[shift - 1]; order[target] = page; break; }
            }
        }
        last_request[page] = (int)time;
    }
    int64_t words[1 + 2 * MAX_N + MAX_REQUESTS] = {0}; words[0] = total_cost;
    for (size_t i = 0; i < n; ++i) words[1 + i] = order[i];
    for (size_t i = 0; i < requests; ++i) words[1 + n + i] = positions[i];
    for (size_t i = 0; i < n; ++i) words[1 + n + requests + i] = bits[i];
    const size_t output_bytes = 8 * (1 + 2 * n + requests);
    if (output == nullptr || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t word = 0; word < 1 + 2 * n + requests; ++word) store_i64_le(staged, 8 * word, words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
