#include <stddef.h>
#include <stdint.h>

enum { MAX_LEAVES = 4, MAX_INPUT_LENGTH = 6 };

typedef struct { int64_t left, right; int operation; } Combination;
typedef struct {
    int n, depth_limit, best_depth, stopped;
    int64_t goal, best, work[2 * MAX_LEAVES];
    Combination current[MAX_LEAVES], saved[MAX_LEAVES];
} Search;

static int64_t distance_from(int64_t a, int64_t b) { return a >= b ? a - b : b - a; }

static int64_t apply(int64_t left, int64_t right, int operation) {
    if (operation == 1) return left + right;
    if (operation == 2) return left - right;
    if (operation == 3) return left * right;
    return left / right;
}

static void search(Search *state, int depth, uint32_t used) {
    if (state->stopped) return;
    if (depth == state->depth_limit) {
        const int64_t candidate = state->work[state->n + depth - 1];
        if (distance_from(candidate, state->goal) < distance_from(state->best, state->goal)) {
            state->best = candidate;
            state->best_depth = depth;
            for (int i = 0; i < depth; ++i) state->saved[i] = state->current[i];
            if (state->best == state->goal) state->stopped = 1;
        }
        return;
    }

    for (int operation = 1; operation <= 4 && !state->stopped; ++operation) {
        for (int first = 0; first < state->n + depth && !state->stopped; ++first) {
            if (used & (UINT32_C(1) << first)) continue;
            for (int second = 0; second < first && !state->stopped; ++second) {
                if (used & (UINT32_C(1) << second)) continue;
                int64_t left = state->work[first], right = state->work[second];
                if ((operation == 3 || operation == 4) && (left == 1 || right == 1)) continue;
                if (left == 0 || right == 0) continue;
                if (operation == 4 && left % right != 0) continue;
                if ((operation == 2 || operation == 4) && left < right) {
                    const int64_t temporary = left; left = right; right = temporary;
                }
                state->current[depth] = (Combination){left, right, operation};
                state->work[state->n + depth] = apply(left, right, operation);
                search(state, depth + 1, used | (UINT32_C(1) << first) | (UINT32_C(1) << second));
            }
        }
    }
}

int64_t mcgill_exptree(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t goal = input[0], raw_count = input[1];
    if (goal < 1 || goal > 1000000000 || raw_count < 1 || raw_count > MAX_LEAVES ||
        length != (size_t)(raw_count + 2)) return -1;

    Search state = {0};
    state.n = (int)raw_count;
    state.goal = goal;
    for (int i = 0; i < state.n; ++i) {
        const int64_t value = input[2 + i];
        if (value < 1 || value > 100) return -1;
        state.work[i] = value;
    }
    for (int i = 0; i < state.n; ++i)
        if (distance_from(state.work[i], state.goal) < distance_from(state.best, state.goal))
            state.best = state.work[i];
    if (state.best == state.goal) return state.best;
    for (state.depth_limit = 1; state.depth_limit < state.n; ++state.depth_limit) {
        search(&state, 0, 0);
        if (state.stopped) break;
    }
    return state.best;
}
