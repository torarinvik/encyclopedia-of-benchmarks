#include <stddef.h>
#include <stdint.h>

#define LIMIT 8

/* The graph is connected; each squaring reduces its diameter by half. */
static void distances(const int adjacency[LIMIT][LIMIT], size_t n, int result[LIMIT][LIMIT]) {
    int square[LIMIT][LIMIT] = {{0}}, expanded[LIMIT][LIMIT] = {{0}};
    int coarse[LIMIT][LIMIT], degree[LIMIT] = {0};
    int complete = 1;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            degree[i] += adjacency[i][j];
            if (i != j && !adjacency[i][j]) complete = 0;
            for (size_t k = 0; k < n; ++k) square[i][j] += adjacency[i][k] * adjacency[k][j];
        }
    }
    if (complete) {
        for (size_t i = 0; i < n; ++i)
            for (size_t j = 0; j < n; ++j) result[i][j] = i == j ? 0 : 1;
        return;
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < n; ++j)
            expanded[i][j] = i != j && (adjacency[i][j] || square[i][j] > 0);
    distances(expanded, n, coarse);
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            if (i == j) { result[i][j] = 0; continue; }
            int neighbor_sum = 0;
            for (size_t k = 0; k < n; ++k) neighbor_sum += coarse[i][k] * adjacency[k][j];
            result[i][j] = 2 * coarse[i][j] - (neighbor_sum < coarse[i][j] * degree[j]);
        }
    }
}

int64_t seidel_unweighted_apsp(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > LIMIT) return -1;
    size_t n = (size_t)input[0];
    if (length != 1 + n * n) return -1;
    int adjacency[LIMIT][LIMIT] = {{0}}, result[LIMIT][LIMIT];
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            int64_t value = input[1 + i * n + j];
            if (value < 0 || value > 1 || (i == j && value != 0)) return -1;
            adjacency[i][j] = (int)value;
        }
    }
    for (size_t i = 0; i < n; ++i)
        for (size_t j = 0; j < i; ++j)
            if (adjacency[i][j] != adjacency[j][i]) return -1;
    int seen[LIMIT] = {0};
    size_t queue[LIMIT], head = 0, tail = 0;
    seen[0] = 1;
    queue[tail++] = 0;
    while (head < tail) {
        size_t vertex = queue[head++];
        for (size_t other = 0; other < n; ++other)
            if (adjacency[vertex][other] && !seen[other]) {
                seen[other] = 1;
                queue[tail++] = other;
            }
    }
    if (tail != n) return -1;
    size_t bytes = 8 * n * n;
    if (output == NULL || capacity < bytes) return -2;
    distances(adjacency, n, result);
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = 0; j < n; ++j) {
            uint64_t bits = (uint64_t)result[i][j];
            for (size_t byte = 0; byte < 8; ++byte) {
                output[8 * (i * n + j) + byte] = (uint8_t)(bits & 255);
                bits >>= 8;
            }
        }
    }
    return (int64_t)bytes;
}
