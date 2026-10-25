module mcgill_exptree;

const int MAX_LEAVES = 4;
struct Combination { long left; long right; int operation; }
struct SearchState {
    int count; int depth_limit; int stopped; long goal; long best;
    long[8] work; Combination[4] current; Combination[4] saved;
}

fn long distance_from(long a, long b) { return a >= b ? a - b : b - a; }
fn long apply(long a, long b, int operation) {
    if (operation == 1) return a + b;
    if (operation == 2) return a - b;
    if (operation == 3) return a * b;
    return a / b;
}
fn void search(SearchState* state, int depth, uint used) {
    if (state.stopped != 0) return;
    if (depth == state.depth_limit) {
        long candidate = state.work[state.count + depth - 1];
        if (distance_from(candidate, state.goal) < distance_from(state.best, state.goal)) {
            state.best = candidate;
            for (int i = 0; i < depth; ++i) state.saved[i] = state.current[i];
            if (state.best == state.goal) state.stopped = 1;
        }
        return;
    }
    for (int operation = 1; operation <= 4 && state.stopped == 0; ++operation) {
        for (int first = 0; first < state.count + depth && state.stopped == 0; ++first) {
            if ((used & (1u << (uint)first)) != 0) continue;
            for (int second = 0; second < first && state.stopped == 0; ++second) {
                if ((used & (1u << (uint)second)) != 0) continue;
                long left = state.work[first];
                long right = state.work[second];
                if ((operation == 3 || operation == 4) && (left == 1 || right == 1)) continue;
                if (left == 0 || right == 0) continue;
                if (operation == 4 && left % right != 0) continue;
                if ((operation == 2 || operation == 4) && left < right) {
                    long temporary = left; left = right; right = temporary;
                }
                state.current[depth].left = left;
                state.current[depth].right = right;
                state.current[depth].operation = operation;
                state.work[state.count + depth] = apply(left, right, operation);
                search(state, depth + 1, used | (1u << (uint)first) | (1u << (uint)second));
            }
        }
    }
}

fn long mcgill_exptree(long* input, usz length) @export("mcgill_exptree") {
    if (input == null || length < 3 || length > 6) return -1;
    long goal = input[0]; long raw_count = input[1];
    if (goal < 1 || goal > 1000000000 || raw_count < 1 || raw_count > MAX_LEAVES ||
        length != (usz)(raw_count + 2)) return -1;
    SearchState state = {0};
    state.count = (int)raw_count; state.goal = goal;
    for (int i = 0; i < state.count; ++i) {
        long value = input[2 + i];
        if (value < 1 || value > 100) return -1;
        state.work[i] = value;
    }
    for (int i = 0; i < state.count; ++i)
        if (distance_from(state.work[i], state.goal) < distance_from(state.best, state.goal)) state.best = state.work[i];
    if (state.best == state.goal) return state.best;
    for (int depth_limit = 1; depth_limit < state.count; ++depth_limit) {
        state.depth_limit = depth_limit;
        search(&state, 0, 0);
        if (state.stopped != 0) break;
    }
    return state.best;
}
