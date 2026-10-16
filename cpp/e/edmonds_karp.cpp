/* Edmonds–Karp maximum flow over a bounded integral capacity matrix. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_VERTICES = 16;
constexpr std::int64_t MAX_CAPACITY = 1000000;
}

extern "C" std::int64_t edmonds_karp(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 3) return -1;
    const std::int64_t n64 = input[0], source64 = input[1], sink64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MAX_VERTICES) || source64 < 0 || source64 >= n64 ||
        sink64 < 0 || sink64 >= n64) return -1;
    const std::size_t n = static_cast<std::size_t>(n64);
    if (length != 3 + n * n) return -1;

    std::int64_t residual[MAX_VERTICES * MAX_VERTICES] = {};
    for (std::size_t row = 0; row < n; ++row) {
        for (std::size_t column = 0; column < n; ++column) {
            const std::int64_t capacity = input[3 + row * n + column];
            if (capacity < 0 || capacity > MAX_CAPACITY || (row == column && capacity != 0)) return -1;
            residual[row * n + column] = capacity;
        }
    }
    for (std::size_t left = 0; left < n; ++left)
        for (std::size_t right = left + 1; right < n; ++right)
            if (residual[left * n + right] > 0 && residual[right * n + left] > 0) return -1;

    const std::size_t source = static_cast<std::size_t>(source64), sink = static_cast<std::size_t>(sink64);
    if (source == sink) return 0;
    std::int64_t total_flow = 0;
    for (;;) {
        int parent[MAX_VERTICES];
        std::size_t queue[MAX_VERTICES];
        for (std::size_t vertex = 0; vertex < n; ++vertex) parent[vertex] = -1;
        parent[source] = static_cast<int>(source);
        std::size_t head = 0, tail = 0;
        queue[tail++] = source;
        while (head < tail && parent[sink] == -1) {
            const std::size_t node = queue[head++];
            for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (residual[node * n + neighbor] <= 0 || parent[neighbor] != -1) continue;
                parent[neighbor] = static_cast<int>(node);
                if (neighbor == sink) break;
                queue[tail++] = neighbor;
            }
        }
        if (parent[sink] == -1) return total_flow;
        std::int64_t path_flow = MAX_CAPACITY;
        for (std::size_t node = sink; node != source; node = static_cast<std::size_t>(parent[node])) {
            const std::size_t previous = static_cast<std::size_t>(parent[node]);
            if (residual[previous * n + node] < path_flow) path_flow = residual[previous * n + node];
        }
        for (std::size_t node = sink; node != source; node = static_cast<std::size_t>(parent[node])) {
            const std::size_t previous = static_cast<std::size_t>(parent[node]);
            residual[previous * n + node] -= path_flow;
            residual[node * n + previous] += path_flow;
        }
        total_flow += path_flow;
    }
}
