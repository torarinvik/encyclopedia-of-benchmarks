#include <stddef.h>
#include <stdint.h>

#define MAX_N 12
#define MAX_M 16
#define MAX_INPUT 18

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t min_sum_set_cover_greedy(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 1 || m64 > MAX_M || length != (size_t)(2 + m64)) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint64_t masks[MAX_M];
    for (size_t set = 0; set < m; ++set) {
        const int64_t mask = input[2 + set];
        if (mask <= 0 || (uint64_t)mask >= (UINT64_C(1) << n)) return -1;
        masks[set] = (uint64_t)mask;
    }
    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    uint8_t covered[MAX_M] = {0}, used[MAX_N] = {0};
    int64_t order[MAX_N];
    int64_t total_time = 0;
    for (size_t slot = 1; slot <= n; ++slot) {
        size_t chosen = 0;
        int best_count = -1;
        for (size_t element = 0; element < n; ++element) {
            if (used[element]) continue;
            int count = 0;
            for (size_t set = 0; set < m; ++set)
                if (!covered[set] && (masks[set] & (UINT64_C(1) << element))) ++count;
            if (count > best_count) { best_count = count; chosen = element; }
        }
        used[chosen] = 1;
        order[slot - 1] = (int64_t)chosen;
        for (size_t set = 0; set < m; ++set) {
            if (!covered[set] && (masks[set] & (UINT64_C(1) << chosen))) {
                covered[set] = 1;
                total_time += (int64_t)slot;
            }
        }
    }
    store_i64_le(output, 0, total_time);
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * (i + 1), order[i]);
    return (int64_t)output_bytes;
}
