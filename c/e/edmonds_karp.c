/* Edmonds–Karp maximum flow over a bounded integral capacity matrix. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_CAPACITY INT64_C(1000000)

int64_t edmonds_karp(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3) return -1;
    const int64_t n64 = input[0], source64 = input[1], sink64 = input[2];
    if (n64 < 1 || n64 > MAX_VERTICES || source64 < 0 || source64 >= n64 ||
        sink64 < 0 || sink64 >= n64) return -1;
    const size_t n = (size_t)n64;
    if (length != 3 + n * n) return -1;

    int64_t residual[MAX_VERTICES * MAX_VERTICES] = {0};
    for (size_t row = 0; row < n; ++row) {
        for (size_t column = 0; column < n; ++column) {
            const int64_t capacity = input[3 + row * n + column];
            if (capacity < 0 || capacity > MAX_CAPACITY || (row == column && capacity != 0)) return -1;
            residual[row * n + column] = capacity;
        }
    }
    for (size_t left = 0; left < n; ++left)
        for (size_t right = left + 1; right < n; ++right)
            if (residual[left * n + right] > 0 && residual[right * n + left] > 0) return -1;

    const size_t source = (size_t)source64, sink = (size_t)sink64;
    if (source == sink) return 0;
    int64_t total_flow = 0;
    for (;;) {
        int parent[MAX_VERTICES];
        size_t queue[MAX_VERTICES];
        for (size_t vertex = 0; vertex < n; ++vertex) parent[vertex] = -1;
        parent[source] = (int)source;
        size_t head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] == -1) {
            const size_t node = queue[head++];
            for (size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (residual[node * n + neighbor] <= 0 || parent[neighbor] != -1) continue;
                parent[neighbor] = (int)node;
                if (neighbor == sink) break;
                queue[tail++] = neighbor;
            }
        }
        if (parent[sink] == -1) return total_flow;

        int64_t path_flow = MAX_CAPACITY;
        for (size_t node = sink; node != source; node = (size_t)parent[node]) {
            const size_t previous = (size_t)parent[node];
            if (residual[previous * n + node] < path_flow) path_flow = residual[previous * n + node];
        }
        for (size_t node = sink; node != source; node = (size_t)parent[node]) {
            const size_t previous = (size_t)parent[node];
            residual[previous * n + node] -= path_flow;
            residual[node * n + previous] += path_flow;
        }
        total_flow += path_flow;
    }
}
