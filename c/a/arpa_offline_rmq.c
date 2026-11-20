#include <stddef.h>
#include <stdint.h>

#define MAX_N 64
#define MAX_Q 64

int64_t arpa_offline_rmq(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > 195) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + n + 2 * q) return -1;
    for (size_t i = 0; i < n; ++i) if (input[2 + i] < -1000 || input[2 + i] > 1000) return -1;
    const size_t query_start = 2 + n;
    for (size_t j = 0; j < q; ++j) {
        const int64_t left = input[query_start + 2 * j], right = input[query_start + 2 * j + 1];
        if (left < 0 || left > right || right >= n_value) return -1;
    }
    int64_t parent[MAX_N], stack[MAX_N], head[MAX_N], next_query[MAX_Q];
    for (size_t i = 0; i < n; ++i) { parent[i] = (int64_t)i; head[i] = -1; }
    for (size_t j = 0; j < q; ++j) {
        const size_t right = (size_t)input[query_start + 2 * j + 1];
        next_query[j] = head[right];
        head[right] = (int64_t)j;
    }
    size_t stack_size = 0;
    int64_t checksum = 0;
    for (size_t right = 0; right < n; ++right) {
        while (stack_size > 0 && input[2 + (size_t)stack[stack_size - 1]] > input[2 + right])
            parent[(size_t)stack[--stack_size]] = (int64_t)right;
        stack[stack_size++] = (int64_t)right;
        for (int64_t query = head[right]; query >= 0; query = next_query[(size_t)query]) {
            const size_t j = (size_t)query;
            size_t node = (size_t)input[query_start + 2 * j];
            size_t root = node;
            while ((size_t)parent[root] != root) root = (size_t)parent[root];
            while ((size_t)parent[node] != node) {
                const size_t next = (size_t)parent[node];
                parent[node] = (int64_t)root;
                node = next;
            }
            checksum += (int64_t)(j + 1) * ((int64_t)root + 1);
        }
    }
    return checksum;
}
