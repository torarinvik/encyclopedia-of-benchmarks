#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 8, MAX_EDGES = 28, MAX_INPUT_LENGTH = 59 };

static int neighbor_precedes(int left, int right, const int degree[MAX_VERTICES]) {
    return degree[left] != degree[right] ? degree[left] < degree[right] : left < right;
}

int64_t reverse_cuthill_mckee(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_VERTICES || m64 < 0 || m64 > MAX_EDGES) return -1;
    int n = (int)n64, m = (int)m64;
    if (m > n * (n - 1) / 2 || length != 2 + 2 * (size_t)m) return -1;

    uint8_t adjacent[MAX_VERTICES][MAX_VERTICES] = {{0}};
    int degree[MAX_VERTICES] = {0};
    int edge_u[MAX_EDGES], edge_v[MAX_EDGES];
    for (int edge = 0; edge < m; ++edge) {
        int64_t left64 = input[2 + 2 * (size_t)edge];
        int64_t right64 = input[3 + 2 * (size_t)edge];
        if (left64 < 0 || right64 < 0 || left64 >= n || right64 >= n || left64 == right64) return -1;
        int left = (int)left64, right = (int)right64;
        if (adjacent[left][right]) return -1;
        adjacent[left][right] = adjacent[right][left] = 1;
        ++degree[left];
        ++degree[right];
        edge_u[edge] = left;
        edge_v[edge] = right;
    }

    uint8_t visited[MAX_VERTICES] = {0};
    int order[MAX_VERTICES], order_count = 0;
    while (order_count < n) {
        int root = -1;
        for (int vertex = 0; vertex < n; ++vertex) {
            if (!visited[vertex] &&
                (root < 0 || degree[vertex] < degree[root] ||
                 (degree[vertex] == degree[root] && vertex < root))) root = vertex;
        }
        int queue[MAX_VERTICES], head = 0, tail = 0;
        visited[root] = 1;
        queue[tail++] = root;
        order[order_count++] = root;
        while (head < tail) {
            int vertex = queue[head++];
            int neighbors[MAX_VERTICES], neighbor_count = 0;
            for (int neighbor = 0; neighbor < n; ++neighbor)
                if (adjacent[vertex][neighbor] && !visited[neighbor]) neighbors[neighbor_count++] = neighbor;
            for (int i = 1; i < neighbor_count; ++i) {
                int key = neighbors[i], j = i;
                while (j > 0 && neighbor_precedes(key, neighbors[j - 1], degree)) {
                    neighbors[j] = neighbors[j - 1];
                    --j;
                }
                neighbors[j] = key;
            }
            for (int i = 0; i < neighbor_count; ++i) {
                int neighbor = neighbors[i];
                if (visited[neighbor]) continue;
                visited[neighbor] = 1;
                queue[tail++] = neighbor;
                order[order_count++] = neighbor;
            }
        }
    }

    for (int left = 0, right = n - 1; left < right; ++left, --right) {
        int temporary = order[left];
        order[left] = order[right];
        order[right] = temporary;
    }
    int position[MAX_VERTICES];
    int64_t rank_word = 0;
    for (int rank = 0; rank < n; ++rank) {
        position[order[rank]] = rank;
        rank_word |= (int64_t)order[rank] << (3 * rank);
    }
    int bandwidth = 0;
    for (int edge = 0; edge < m; ++edge) {
        int difference = position[edge_u[edge]] - position[edge_v[edge]];
        if (difference < 0) difference = -difference;
        if (difference > bandwidth) bandwidth = difference;
    }
    return ((int64_t)bandwidth << 24) | rank_word;
}
