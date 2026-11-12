#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, ENCODING_BASE = 65 };

static int64_t next_node(const int64_t *input, int64_t node) {
    return input[2 + (size_t)node];
}

static int64_t cycle_parameters(const int64_t *input, int64_t start) {
    int64_t tortoise = next_node(input, start);
    int64_t hare = next_node(input, next_node(input, start));
    while (tortoise != hare) {
        tortoise = next_node(input, tortoise);
        hare = next_node(input, next_node(input, hare));
    }
    int64_t mu = 0;
    tortoise = start;
    while (tortoise != hare) {
        tortoise = next_node(input, tortoise);
        hare = next_node(input, hare);
        ++mu;
    }
    int64_t lambda = 1;
    hare = next_node(input, tortoise);
    while (hare != tortoise) {
        hare = next_node(input, hare);
        ++lambda;
    }
    return ENCODING_BASE * mu + lambda;
}

int64_t functional_graph_cycle_parameters(const int64_t *input, size_t length) {
    if (!input || length < 3 || length > MAX_N + 2) return -1;
    const int64_t n = input[0], start = input[1];
    if (n < 1 || n > MAX_N || start < 0 || start >= n || length != (size_t)(n + 2)) return -1;
    for (int64_t i = 0; i < n; ++i) {
        if (input[2 + (size_t)i] < 0 || input[2 + (size_t)i] >= n) return -1;
    }
    return cycle_parameters(input, start);
}
