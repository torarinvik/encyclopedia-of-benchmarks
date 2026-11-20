/* Bounded synchronous-round push-relabel; rounds are simulated sequentially. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_ARCS 24
#define MAX_INPUT_LENGTH 77
#define MAX_CAPACITY 15

int64_t synchronous_round_push_relabel(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    int64_t raw_n = input[0], raw_m = input[1];
    int64_t raw_source = input[2], raw_sink = input[3];
    if (raw_n < 2 || raw_n > MAX_VERTICES || raw_m < 0 || raw_m > MAX_ARCS ||
        raw_source < 0 || raw_source >= raw_n || raw_sink < 0 || raw_sink >= raw_n ||
        raw_source == raw_sink || length != (size_t)(4 + 3 * raw_m)) return -1;
    int n = (int)raw_n, m = (int)raw_m;
    int source = (int)raw_source, sink = (int)raw_sink;
    int64_t capacity[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (int i = 0; i < m; ++i) {
        size_t offset = 4 + 3 * (size_t)i;
        int64_t u = input[offset], v = input[offset + 1], c = input[offset + 2];
        if (u < 0 || u >= n || v < 0 || v >= n || u == v || c < 0 || c > MAX_CAPACITY)
            return -1;
        capacity[u][v] += c;
    }

    int64_t residual[MAX_VERTICES][MAX_VERTICES] = {{0}};
    int64_t excess[MAX_VERTICES] = {0};
    int height[MAX_VERTICES] = {0};
    for (int u = 0; u < n; ++u)
        for (int v = 0; v < n; ++v) residual[u][v] = capacity[u][v];
    height[source] = n;
    for (int v = 0; v < n; ++v) {
        if (v == source) continue;
        int64_t amount = residual[source][v];
        if (amount != 0) {
            residual[source][v] = 0;
            residual[v][source] += amount;
            excess[source] -= amount;
            excess[v] += amount;
        }
    }

    for (;;) {
        int active[MAX_VERTICES], active_count = 0;
        for (int v = 0; v < n; ++v)
            if (v != source && v != sink && excess[v] > 0 && height[v] < n)
                active[active_count++] = v;
        if (active_count == 0) return excess[sink];

        int64_t change[MAX_VERTICES] = {0};
        for (int ai = 0; ai < active_count; ++ai) {
            int u = active[ai];
            int64_t remaining = excess[u];
            for (int v = 0; v < n && remaining > 0; ++v) {
                if (residual[u][v] > 0 && height[u] == height[v] + 1) {
                    int64_t amount = remaining < residual[u][v] ? remaining : residual[u][v];
                    residual[u][v] -= amount;
                    residual[v][u] += amount;
                    change[u] -= amount;
                    change[v] += amount;
                    remaining -= amount;
                }
            }
        }

        int64_t next_excess[MAX_VERTICES];
        int next_height[MAX_VERTICES];
        for (int v = 0; v < n; ++v) {
            next_excess[v] = excess[v] + change[v];
            next_height[v] = height[v];
        }
        for (int ai = 0; ai < active_count; ++ai) {
            int u = active[ai];
            if (next_excess[u] <= 0) continue;
            int minimum = 2 * MAX_VERTICES + 1;
            for (int v = 0; v < n; ++v)
                if (residual[u][v] > 0 && height[v] < minimum) minimum = height[v];
            next_height[u] = minimum == 2 * MAX_VERTICES + 1 ? n + 1 : minimum + 1;
        }
        for (int v = 0; v < n; ++v) {
            excess[v] = next_excess[v];
            height[v] = next_height[v];
        }
    }
}
