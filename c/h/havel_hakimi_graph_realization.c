#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 28
#define MAX_PARSEABLE_LENGTH 10
#define MAX_OUTPUT_BYTES 464

static void store_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) { output[offset + i] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t havel_hakimi_graph_realization(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_VERTICES) return -1;
    size_t n = (size_t)n_value;
    if (length != n + 1) return -1;
    int residual[MAX_VERTICES] = {0};
    int active[MAX_VERTICES] = {0};
    for (size_t i = 0; i < n; ++i) {
        int64_t d = input[i + 1];
        if (d < 0 || d >= n_value) return -1;
        residual[i] = (int)d; active[i] = 1;
    }
    int edges[MAX_EDGES][2]; size_t edge_count = 0;
    int graphical = 1;
    while (graphical) {
        int hub = -1;
        for (size_t v = 0; v < n; ++v)
            if (active[v] && residual[v] > 0 &&
                (hub < 0 || residual[v] > residual[hub] ||
                 (residual[v] == residual[hub] && (int)v < hub))) hub = (int)v;
        if (hub < 0) break;
        int degree = residual[hub]; residual[hub] = 0; active[hub] = 0;
        int candidates[MAX_VERTICES]; size_t candidate_count = 0;
        for (size_t v = 0; v < n; ++v) if (active[v]) candidates[candidate_count++] = (int)v;
        for (size_t i = 1; i < candidate_count; ++i) {
            int value = candidates[i]; size_t j = i;
            while (j > 0 && (residual[candidates[j - 1]] < residual[value] ||
                   (residual[candidates[j - 1]] == residual[value] && candidates[j - 1] > value))) {
                candidates[j] = candidates[j - 1]; --j;
            }
            candidates[j] = value;
        }
        if ((size_t)degree > candidate_count) { graphical = 0; break; }
        for (int i = 0; i < degree; ++i) {
            int neighbor = candidates[i];
            if (residual[neighbor] == 0) { graphical = 0; break; }
            --residual[neighbor];
            edges[edge_count][0] = hub < neighbor ? hub : neighbor;
            edges[edge_count][1] = hub < neighbor ? neighbor : hub;
            ++edge_count;
        }
    }
    int64_t words[2 + 2 * MAX_EDGES]; size_t word_count = 0;
    if (graphical) {
        words[word_count++] = 1; words[word_count++] = (int64_t)edge_count;
        for (size_t i = 0; i < edge_count; ++i) { words[word_count++] = edges[i][0]; words[word_count++] = edges[i][1]; }
    } else { words[word_count++] = 0; }
    if (output == NULL || capacity < word_count * 8) return -2;
    for (size_t i = 0; i < word_count; ++i) store_i64(output, 8 * i, words[i]);
    return (int64_t)(word_count * 8);
}
