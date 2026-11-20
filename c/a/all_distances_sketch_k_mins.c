#include <stddef.h>
#include <stdint.h>

#define ADM_MAX_N 6
#define ADM_MAX_ASSIGNMENTS 3
#define ADM_MAX_INPUT 27
#define ADM_MAX_WORDS 73

static void adm_put_i64(uint8_t *output, size_t word, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[8 * word + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t all_distances_sketch_k_mins(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > ADM_MAX_INPUT) return -1;
    const int64_t n0 = input[0], assignments0 = input[1];
    if (n0 < 1 || n0 > ADM_MAX_N || assignments0 < 1
            || assignments0 > ADM_MAX_ASSIGNMENTS) return -1;
    const size_t n = (size_t)n0, assignments = (size_t)assignments0;
    if (length != 2 + n + assignments * n) return -1;

    int64_t distances[ADM_MAX_N];
    for (size_t item = 0; item < n; ++item) {
        const int64_t distance = input[2 + item];
        if (distance < 0 || distance > 1000000
                || (item > 0 && distances[item - 1] >= distance)) return -1;
        distances[item] = distance;
    }

    int64_t ranks[ADM_MAX_ASSIGNMENTS][ADM_MAX_N] = {{0}};
    for (size_t assignment = 0; assignment < assignments; ++assignment) {
        uint8_t seen[ADM_MAX_N] = {0};
        for (size_t item = 0; item < n; ++item) {
            const int64_t rank = input[2 + n + assignment * n + item];
            if (rank < 0 || rank >= n0 || seen[(size_t)rank]) return -1;
            seen[(size_t)rank] = 1;
            ranks[assignment][item] = rank;
        }
    }

    int64_t staged[ADM_MAX_WORDS] = {0};
    size_t count = 0;
    for (size_t assignment = 0; assignment < assignments; ++assignment) {
        int64_t best_rank = n0;
        for (size_t item = 0; item < n; ++item) {
            const int64_t rank = ranks[assignment][item];
            if (rank < best_rank) {
                staged[1 + 4 * count] = (int64_t)assignment;
                staged[2 + 4 * count] = (int64_t)item;
                staged[3 + 4 * count] = rank;
                staged[4 + 4 * count] = distances[item];
                ++count;
                best_rank = rank;
            }
        }
    }
    staged[0] = (int64_t)count;
    const size_t words = 1 + 4 * count, bytes = 8 * words;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t word = 0; word < words; ++word) adm_put_i64(output, word, staged[word]);
    return (int64_t)bytes;
}
