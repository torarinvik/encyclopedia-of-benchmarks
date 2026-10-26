#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_ITERS = 20, MAX_INPUT = 2 + MAX_N * MAX_N };

int64_t gapbs_pagerank_pull_gs(const int64_t *input, size_t length) {
    if (input == NULL || length < 6 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], iterations64 = input[1];
    if (n64 < 2 || n64 > MAX_N || iterations64 < 0 || iterations64 > MAX_ITERS) return -1;
    const size_t n = (size_t)n64, iterations = (size_t)iterations64;
    if (length != 2 + n * n) return -1;
    uint8_t matrix[MAX_N * MAX_N] = {0};
    size_t outdegree[MAX_N] = {0};
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const int64_t value = input[2 + row * n + column];
            if ((value != 0 && value != 1) || (row == column && value != 0)) return -1;
            matrix[row * n + column] = (uint8_t)value;
            outdegree[row] += (size_t)value;
        }
        if (outdegree[row] == 0) return -1;
    }
    const float damping = 0.85f;
    const float init_score = 1.0f / (float)n;
    const float base_score = (1.0f - damping) / (float)n;
    float scores[MAX_N], outgoing[MAX_N];
    for (size_t node = 0; node < n; ++node) {
        scores[node] = init_score;
        outgoing[node] = init_score / (float)outdegree[node];
    }
    for (size_t iteration = 0; iteration < iterations; ++iteration) {
        for (size_t target = 0; target < n; ++target) {
            float incoming = 0.0f;
            for (size_t source = 0; source < n; ++source)
                if (matrix[source * n + target] != 0) incoming += outgoing[source];
            scores[target] = base_score + damping * incoming;
            outgoing[target] = scores[target] / (float)outdegree[target];
        }
    }
    double weighted = 0.0;
    for (size_t node = 0; node < n; ++node) weighted += (double)(node + 1) * (double)scores[node];
    return (int64_t)(weighted * 100.0 + 0.5);
}
