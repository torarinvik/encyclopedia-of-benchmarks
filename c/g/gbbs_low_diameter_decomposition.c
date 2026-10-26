/* Clean-room bounded GBBS MPX low-diameter decomposition profile. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_M = 24, MAX_INPUT = 2 + 2 * MAX_M, MAX_ROUNDS = 13 };
static const size_t batch_size[MAX_ROUNDS] = {1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11};

int64_t gbbs_low_diameter_decomposition(const int64_t *input, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
    }
    if (output == NULL || capacity < n) return -2;

    int16_t label[MAX_N];
    size_t frontier[MAX_N], frontier_count = 0;
    size_t cursor = 0, assigned = 0, round = 0;
    for (size_t vertex = 0; vertex < n; ++vertex) label[vertex] = -1;
    while (assigned < n) {
        size_t end = cursor + batch_size[round];
        if (end > n) end = n;
        for (size_t candidate = cursor; candidate < end; ++candidate) {
            if (label[candidate] < 0) {
                label[candidate] = (int16_t)candidate;
                frontier[frontier_count++] = candidate;
                ++assigned;
            }
        }
        cursor = end;
        if (assigned == n) break;

        int16_t reached[MAX_N];
        for (size_t vertex = 0; vertex < n; ++vertex) reached[vertex] = -1;
        for (size_t i = 0; i < frontier_count; ++i) {
            const size_t vertex = frontier[i];
            for (size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacent[vertex][neighbor] && label[neighbor] < 0 &&
                    (reached[neighbor] < 0 || label[vertex] < reached[neighbor]))
                    reached[neighbor] = label[vertex];
            }
        }
        frontier_count = 0;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (reached[vertex] >= 0) {
                label[vertex] = reached[vertex];
                frontier[frontier_count++] = vertex;
                ++assigned;
            }
        }
        ++round;
    }
    for (size_t vertex = 0; vertex < n; ++vertex) output[vertex] = (uint8_t)label[vertex];
    return (int64_t)n;
}
