#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_INPUT_VALUES 257
#define MAX_WEIGHT 1000000

int64_t stoer_wagner(const int64_t *input, size_t length)
{
    if (!input || length < 1 || length > MAX_INPUT_VALUES) return -1;
    const int64_t n_value = input[0];
    if (n_value < 2 || n_value > MAX_N) return -1;
    const int n = (int)n_value;
    if (length != (size_t)(1 + n * n)) return -1;

    int64_t graph[MAX_N][MAX_N] = {{0}};
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            const int64_t weight = input[1 + i * n + j];
            if (weight < 0 || weight > MAX_WEIGHT) return -1;
            graph[i][j] = weight;
        }
    }
    for (int i = 0; i < n; ++i) {
        if (graph[i][i] != 0) return -1;
        for (int j = i + 1; j < n; ++j) {
            if (graph[i][j] != graph[j][i]) return -1;
        }
    }

    bool merged[MAX_N] = {false};
    int64_t min_cut = 120000001;
    for (int phase = 0; phase < n - 1; ++phase) {
        bool in_set[MAX_N] = {false};
        int64_t weights[MAX_N] = {0};
        int previous = -1;
        int last = -1;
        for (int step = 0; step < n - phase; ++step) {
            int current = -1;
            int64_t max_weight = -1;
            for (int vertex = 0; vertex < n; ++vertex) {
                if (!merged[vertex] && !in_set[vertex] && weights[vertex] > max_weight) {
                    max_weight = weights[vertex];
                    current = vertex;
                }
            }
            if (current < 0) break;
            in_set[current] = true;
            previous = last;
            last = current;
            for (int vertex = 0; vertex < n; ++vertex) {
                if (!merged[vertex] && !in_set[vertex]) {
                    weights[vertex] += graph[current][vertex];
                }
            }
        }
        if (last < 0 || previous < 0) return -1;
        if (weights[last] < min_cut) min_cut = weights[last];
        for (int vertex = 0; vertex < n; ++vertex) {
            graph[previous][vertex] += graph[last][vertex];
            graph[vertex][previous] = graph[previous][vertex];
        }
        merged[last] = true;
    }
    return min_cut;
}
