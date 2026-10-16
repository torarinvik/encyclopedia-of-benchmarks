#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 256
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGES)
#define MAX_DEGREE (2 * MAX_EDGES)
#define MAX_ROUTE (MAX_EDGES + 1)
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)
#define LOW63_MASK UINT64_C(0x7fffffffffffffff)

static uint64_t hash_word(uint64_t hash, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (int byte = 0; byte < 8; ++byte) {
        hash = (hash ^ (uint8_t)bits) * FNV_PRIME;
        bits >>= 8;
    }
    return hash;
}

int64_t hierholzer_algorithm(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 0 || n64 > MAX_VERTICES || m64 < 0 || m64 > MAX_EDGES ||
        length != 2 + 2 * (size_t)m64) return -1;
    const int n = (int)n64, m = (int)m64;

    int adjacency[MAX_VERTICES][MAX_DEGREE] = {{0}};
    int degree[MAX_VERTICES] = {0};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || u64 >= n || v64 < 0 || v64 >= n) return -1;
        const int u = (int)u64, v = (int)v64;
        adjacency[u][degree[u]++] = v;
        adjacency[v][degree[v]++] = u;
    }

    int has_circuit = 1;
    int start = -1;
    for (int vertex = 0; vertex < n; ++vertex) {
        if ((degree[vertex] & 1) != 0) has_circuit = 0;
        if (start < 0 && degree[vertex] > 0) start = vertex;
    }
    if (has_circuit && start >= 0) {
        uint8_t seen[MAX_VERTICES] = {0};
        int stack[MAX_VERTICES], top = 0;
        seen[start] = 1; stack[top++] = start;
        while (top > 0) {
            const int vertex = stack[--top];
            for (int i = 0; i < degree[vertex]; ++i) {
                const int neighbor = adjacency[vertex][i];
                if (!seen[neighbor]) { seen[neighbor] = 1; stack[top++] = neighbor; }
            }
        }
        for (int vertex = 0; vertex < n; ++vertex)
            if (degree[vertex] > 0 && !seen[vertex]) has_circuit = 0;
    }

    int route[MAX_ROUTE], route_length = 0;
    if (has_circuit) {
        if (start < 0) {
            if (n > 0) route[route_length++] = 0;
        } else {
            uint8_t used[MAX_VERTICES][MAX_DEGREE] = {{0}};
            int head[MAX_VERTICES] = {0};
            int pair_cursor[MAX_VERTICES][MAX_VERTICES] = {{0}};
            int path[MAX_ROUTE], path_size = 0;
            path[path_size++] = start;
            while (path_size > 0) {
                const int current = path[path_size - 1];
                while (head[current] < degree[current] && used[current][head[current]]) ++head[current];
                if (head[current] < degree[current]) {
                    const int position = head[current];
                    used[current][position] = 1;
                    const int next = adjacency[current][position];
                    int reverse = pair_cursor[next][current];
                    while (reverse < degree[next] &&
                           (used[next][reverse] || adjacency[next][reverse] != current)) ++reverse;
                    if (reverse >= degree[next]) return -1;
                    used[next][reverse] = 1;
                    pair_cursor[next][current] = reverse + 1;
                    path[path_size++] = next;
                } else {
                    route[route_length++] = path[--path_size];
                }
            }
            for (int left = 0, right = route_length - 1; left < right; ++left, --right) {
                const int temp = route[left]; route[left] = route[right]; route[right] = temp;
            }
        }
    }

    uint64_t hash = FNV_OFFSET;
    hash = hash_word(hash, has_circuit);
    hash = hash_word(hash, route_length);
    for (int i = 0; i < route_length; ++i) hash = hash_word(hash, route[i]);
    return (int64_t)(hash & LOW63_MASK);
}
