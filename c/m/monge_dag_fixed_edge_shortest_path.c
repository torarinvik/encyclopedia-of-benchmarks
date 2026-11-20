#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, SIDE = MAX_N + 1, MAX_INPUT = 531, MAX_FRAMES = 64 };
static const int64_t INF = INT64_MAX / 4;

typedef struct { size_t row_begin, row_end, col_begin, col_end; } Frame;

static void monge_layer(size_t n, size_t layer, const int64_t dp[SIDE],
                        const int64_t cost[SIDE * SIDE], int64_t next[SIDE])
{
    Frame stack[MAX_FRAMES];
    size_t stack_size = 0;
    stack[stack_size++] = (Frame){layer, n + 1, layer - 1, n};
    while (stack_size != 0) {
        const Frame frame = stack[--stack_size];
        if (frame.row_begin >= frame.row_end) continue;
        const size_t row = (frame.row_begin + frame.row_end) / 2;
        size_t upper = frame.col_end < row ? frame.col_end : row;
        size_t best_column = frame.col_begin;
        int64_t best_value = INF;
        for (size_t column = frame.col_begin; column < upper; ++column) {
            if (dp[column] == INF) continue;
            const int64_t candidate = dp[column] + cost[column * SIDE + row];
            if (candidate < best_value) { best_value = candidate; best_column = column; }
        }
        next[row] = best_value;
        if (row + 1 < frame.row_end && best_column < frame.col_end)
            stack[stack_size++] = (Frame){row + 1, frame.row_end, best_column, frame.col_end};
        if (frame.row_begin < row && frame.col_begin < best_column + 1)
            stack[stack_size++] = (Frame){frame.row_begin, row, frame.col_begin, best_column + 1};
    }
}

int64_t monge_dag_fixed_edge_shortest_path(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 1 || input[1] > input[0]) return -1;
    const size_t n = (size_t)input[0], layers = (size_t)input[1];
    if (length != 2 + n * (n + 1) / 2) return -1;

    int64_t cost[SIDE * SIDE] = {0};
    size_t offset = 2;
    for (size_t u = 0; u < n; ++u) {
        for (size_t v = u + 1; v <= n; ++v) {
            const int64_t weight = input[offset++];
            if (weight < 0 || weight > 1000000) return -1;
            cost[u * SIDE + v] = weight;
        }
    }
    for (size_t u = 0; u + 1 < n; ++u) {
        for (size_t v = u + 2; v < n; ++v) {
            if (cost[u * SIDE + v] + cost[(u + 1) * SIDE + v + 1] >
                cost[u * SIDE + v + 1] + cost[(u + 1) * SIDE + v]) return -1;
        }
    }

    int64_t dp[SIDE], next[SIDE];
    for (size_t v = 0; v <= n; ++v) dp[v] = INF;
    dp[0] = 0;
    for (size_t layer = 1; layer <= layers; ++layer) {
        for (size_t v = 0; v <= n; ++v) next[v] = INF;
        monge_layer(n, layer, dp, cost, next);
        for (size_t v = 0; v <= n; ++v) dp[v] = next[v];
    }
    return dp[n];
}
