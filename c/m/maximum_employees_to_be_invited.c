#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 10 };

int64_t maximum_employees_to_be_invited(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_value = input[0];
    if (n_value < 2 || n_value > MAX_N || length != (size_t)(n_value + 1)) return -1;
    const size_t n = (size_t)n_value;
    int64_t favorite[MAX_N];
    int64_t indegree[MAX_N] = {0};
    int64_t chain[MAX_N];
    int64_t queue[MAX_N];
    int64_t visited[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t target = input[i + 1];
        if (target < 0 || target >= n_value || target == (int64_t)i) return -1;
        favorite[i] = target;
        chain[i] = 1;
        ++indegree[target];
    }

    size_t head = 0, tail = 0;
    for (size_t i = 0; i < n; ++i)
        if (indegree[i] == 0) queue[tail++] = (int64_t)i;
    while (head < tail) {
        const int64_t node = queue[head++];
        const int64_t target = favorite[node];
        if (chain[node] + 1 > chain[target]) chain[target] = chain[node] + 1;
        if (--indegree[target] == 0) queue[tail++] = target;
    }

    int64_t pair_total = 0, longest_cycle = 0;
    for (size_t start = 0; start < n; ++start) {
        if (indegree[start] == 0 || visited[start]) continue;
        int64_t node = (int64_t)start, first = -1, second = -1, cycle_length = 0;
        while (!visited[node]) {
            visited[node] = 1;
            if (cycle_length == 0) first = node;
            else if (cycle_length == 1) second = node;
            ++cycle_length;
            node = favorite[node];
        }
        if (cycle_length == 2) pair_total += chain[first] + chain[second];
        else if (cycle_length > longest_cycle) longest_cycle = cycle_length;
    }
    return pair_total > longest_cycle ? pair_total : longest_cycle;
}
