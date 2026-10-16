/* Iterative reachability search in a bounded undirected graph. */
#include <stddef.h>
#include <stdint.h>
#define MAX_VERTICES 64
#define MAX_EDGES 256
int64_t depth_first_search_iterative(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 518) return -1;
    const int64_t n = input[0], m = input[1], source_value = input[2], target = input[3];
    if (n < 1 || n > MAX_VERTICES || m < 0 || m > MAX_EDGES || source_value < 0 || source_value >= n) return -1;
    if (length != 4 + 2 * (size_t)m) return -1;
    for (size_t edge = 0; edge < (size_t)m; ++edge) {
        const int64_t left = input[4 + 2 * edge], right = input[5 + 2 * edge];
        if (left < 0 || left >= n || right < 0 || right >= n) return -1;
    }
    uint8_t visited[MAX_VERTICES] = {0};
    size_t pending[MAX_VERTICES], top = 1;
    pending[0] = (size_t)source_value;
    visited[pending[0]] = 1;
    while (top > 0) {
        const size_t current = pending[--top];
        if ((int64_t)current == target) return 1;
        for (size_t edge = 0; edge < (size_t)m; ++edge) {
            const int64_t left = input[4 + 2 * edge], right = input[5 + 2 * edge];
            const int64_t neighbor = left == (int64_t)current ? right : right == (int64_t)current ? left : -1;
            if (neighbor >= 0 && !visited[(size_t)neighbor]) {
                visited[(size_t)neighbor] = 1;
                pending[top++] = (size_t)neighbor;
            }
        }
    }
    return 0;
}
