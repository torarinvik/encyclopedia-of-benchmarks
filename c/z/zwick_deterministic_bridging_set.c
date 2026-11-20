#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 131, MAX_CONSTRAINTS = 64, INF_DIST = 9 };

typedef struct {
    int n, threshold;
    uint8_t edge[64], witness[64], distance[64];
    uint16_t constraints[MAX_CONSTRAINTS];
    int constraint_count;
} State;

static int popcount16(uint16_t value) {
    int count = 0;
    while (value != 0) { count += value & 1u; value >>= 1; }
    return count;
}

static int subpath(const State *state, int from, int to, int limit, uint8_t *out) {
    if (limit <= 0 || state->witness[from * state->n + to] == 0) return 0;
    const int middle = (int)state->witness[from * state->n + to] - 1;
    int count = subpath(state, from, middle, limit - 1, out);
    out[count++] = (uint8_t)middle;
    const int remaining = limit - count;
    if (remaining > 0)
        count += subpath(state, middle, to, remaining, out + count);
    return count;
}

static int decode(State *state, const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return 0;
    if (input[0] < 2 || input[0] > MAX_N) return 0;
    const int n = (int)input[0];
    if (input[1] < 2 || input[1] > n || length != (size_t)(2 + 2 * n * n)) return 0;
    state->n = n;
    state->threshold = (int)input[1];
    state->constraint_count = 0;
    const size_t matrix = (size_t)n * (size_t)n;
    for (size_t i = 0; i < matrix; ++i) {
        if (input[2 + i] < 0 || input[2 + i] > 1) return 0;
        if (input[2 + matrix + i] < 0 || input[2 + matrix + i] > n) return 0;
        state->edge[i] = (uint8_t)input[2 + i];
        state->witness[i] = (uint8_t)input[2 + matrix + i];
    }
    for (int i = 0; i < n; ++i)
        if (state->edge[i * n + i] != 0) return 0;

    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j)
            state->distance[i * n + j] = (uint8_t)(i == j ? 0 :
                (state->edge[i * n + j] ? 1 : INF_DIST));
    for (int k = 0; k < n; ++k)
        for (int i = 0; i < n; ++i)
            for (int j = 0; j < n; ++j) {
                const int candidate = state->distance[i * n + k] + state->distance[k * n + j];
                if (candidate < state->distance[i * n + j])
                    state->distance[i * n + j] = (uint8_t)candidate;
            }
    for (int i = 0; i < n; ++i)
        for (int j = 0; j < n; ++j) {
            const int d = state->distance[i * n + j];
            const int w = state->witness[i * n + j];
            if (d >= INF_DIST) return 0;
            if (d <= 1) {
                if (w != 0) return 0;
            } else {
                if (w == 0) return 0;
                const int v = w - 1;
                if (v == i || v == j) return 0;
                const int left = state->distance[i * n + v];
                const int right = state->distance[v * n + j];
                if (left + right != d || left >= d || right >= d) return 0;
            }
        }
    return 1;
}

int64_t zwick_deterministic_bridging_set(const int64_t *input, size_t length) {
    State state = {0};
    if (!decode(&state, input, length)) return -1;
    for (int i = 0; i < state.n; ++i)
        for (int j = 0; j < state.n; ++j) {
            uint8_t internal[MAX_N] = {0};
            const int count = subpath(&state, i, j, state.threshold, internal);
            uint16_t mask = (uint16_t)((1u << i) | (1u << j));
            for (int k = 0; k < count; ++k) mask |= (uint16_t)(1u << internal[k]);
            if (popcount16(mask) >= state.threshold) {
                int duplicate = 0;
                for (int c = 0; c < state.constraint_count; ++c)
                    if (state.constraints[c] == mask) { duplicate = 1; break; }
                if (!duplicate) state.constraints[state.constraint_count++] = mask;
            }
        }

    uint8_t unhit[MAX_CONSTRAINTS] = {0};
    for (int i = 0; i < state.constraint_count; ++i) unhit[i] = 1;
    int remaining = state.constraint_count;
    uint16_t selected = 0;
    while (remaining > 0) {
        int best_vertex = -1, best_score = -1;
        for (int v = 0; v < state.n; ++v) {
            int score = 0;
            for (int c = 0; c < state.constraint_count; ++c)
                if (unhit[c] && (state.constraints[c] & (uint16_t)(1u << v))) ++score;
            if (score > best_score) { best_score = score; best_vertex = v; }
        }
        if (best_score <= 0 || best_vertex < 0) return -1;
        selected |= (uint16_t)(1u << best_vertex);
        for (int c = 0; c < state.constraint_count; ++c)
            if (unhit[c] && (state.constraints[c] & (uint16_t)(1u << best_vertex))) {
                unhit[c] = 0;
                --remaining;
            }
    }
    return (int64_t)selected;
}
