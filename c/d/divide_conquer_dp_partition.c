#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_GROUPS = 8, MAX_INPUT = 66, STACK_CAPACITY = 136 };
static const int64_t INF = INT64_MAX / 4;

typedef struct { size_t left, right, low, high; } Task;

static void compute_row(const int64_t *previous, int64_t *current,
                        const int64_t *prefix, size_t n, size_t group) {
    Task stack[STACK_CAPACITY];
    size_t top = 0;
    stack[top++] = (Task){group, n, group - 1, n - 1};
    while (top != 0) {
        Task task = stack[--top];
        if (task.left > task.right) continue;
        size_t middle = task.left + (task.right - task.left) / 2;
        size_t upper = task.high < middle - 1 ? task.high : middle - 1;
        int64_t best = INF;
        size_t best_split = task.low;
        for (size_t split = task.low; split <= upper; ++split) {
            if (previous[split] == INF) continue;
            int64_t segment = prefix[middle] - prefix[split];
            int64_t candidate = previous[split] + segment * segment;
            if (candidate < best) { best = candidate; best_split = split; }
        }
        current[middle] = best;
        if (middle < task.right)
            stack[top++] = (Task){middle + 1, task.right, best_split, task.high};
        if (task.left < middle)
            stack[top++] = (Task){task.left, middle - 1, task.low, best_split};
    }
}

int64_t divide_conquer_dp_partition(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n_value = values[0], groups_value = values[1];
    if (n_value < 1 || n_value > MAX_N || groups_value < 1 ||
        groups_value > MAX_GROUPS || groups_value > n_value || length != (size_t)n_value + 2) return -1;
    size_t n = (size_t)n_value, groups = (size_t)groups_value;
    int64_t prefix[MAX_N + 1] = {0};
    int64_t first[MAX_N + 1], second[MAX_N + 1];
    for (size_t i = 0; i < n; ++i) {
        int64_t value = values[i + 2];
        if (value < 0 || value > 1000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    for (size_t i = 0; i <= n; ++i) first[i] = INF;
    first[0] = 0;
    int64_t *previous = first, *current = second;
    for (size_t group = 1; group <= groups; ++group) {
        for (size_t i = 0; i <= n; ++i) current[i] = INF;
        compute_row(previous, current, prefix, n, group);
        int64_t *temporary = previous; previous = current; current = temporary;
    }
    return previous[n];
}
