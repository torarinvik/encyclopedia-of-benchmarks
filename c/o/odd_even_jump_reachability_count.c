#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_PARSEABLE = 66 };

static bool comes_before(const int64_t *values, size_t left, size_t right,
                         bool descending) {
    if (values[left] != values[right])
        return descending ? values[left] > values[right] : values[left] < values[right];
    return left < right;
}

static void build_successors(const int64_t *values, size_t n, bool descending,
                             int64_t *target) {
    size_t order[MAX_N] = {0};
    size_t stack[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        order[i] = i;
        target[i] = -1;
    }
    for (size_t i = 1; i < n; ++i) {
        const size_t key = order[i];
        size_t position = i;
        while (position > 0 && comes_before(values, key, order[position - 1], descending)) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = key;
    }
    size_t stack_size = 0;
    for (size_t i = 0; i < n; ++i) {
        const size_t index = order[i];
        while (stack_size > 0 && stack[stack_size - 1] < index)
            target[stack[--stack_size]] = (int64_t)index;
        stack[stack_size++] = index;
    }
}

int64_t odd_even_jump_reachability_count(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE) return -1;
    if (input[0] < 1 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    if (length != n + 1) return -1;
    const int64_t *values = input + 1;
    for (size_t i = 0; i < n; ++i)
        if (values[i] < -1000000 || values[i] > 1000000) return -1;

    int64_t odd_next[MAX_N], even_next[MAX_N];
    bool odd[MAX_N] = {false}, even[MAX_N] = {false};
    build_successors(values, n, false, odd_next);
    build_successors(values, n, true, even_next);
    odd[n - 1] = true;
    even[n - 1] = true;
    size_t index = n - 1;
    while (index > 0) {
        --index;
        if (odd_next[index] >= 0) odd[index] = even[(size_t)odd_next[index]];
        if (even_next[index] >= 0) even[index] = odd[(size_t)even_next[index]];
    }
    int64_t count = 0;
    for (size_t i = 0; i < n; ++i) count += odd[i] ? 1 : 0;
    return count;
}
