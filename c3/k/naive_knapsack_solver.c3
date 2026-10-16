module naive_knapsack_solver;

const usz MAX_ITEMS = 30;
const long LIMIT = 1000000;

fn long naive_knapsack_solver(long* values, usz length) @export("naive_knapsack_solver") {
    if (values == null || length < 2 || length > MAX_ITEMS + 2) return -1;
    long capacity = values[0]; long count = values[1];
    if (capacity < 0 || capacity > LIMIT || count < 0 || count > 30 || length != (usz)count + 2) return -1;
    long weight = 0; long mask = 0;
    for (usz i = 0; i < (usz)count; i++) {
        long item = values[i + 2];
        if (item < 0 || item > LIMIT) return -1;
        if (weight + item <= capacity) { weight += item; mask |= 1L << i; }
    }
    return mask;
}
