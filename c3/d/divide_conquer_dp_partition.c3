module divide_conquer_dp_partition;

const usz MAX_N = 64, MAX_GROUPS = 8, MAX_INPUT = 66, STACK_CAPACITY = 136;
const long INF = 0x1FFFFFFFFFFFFFFF;
struct Task { usz left; usz right; usz low; usz high; }

fn void compute_row(long* previous, long* current, long* prefix, usz n, usz group) {
    Task[STACK_CAPACITY] stack;
    usz top = 0;
    stack[top++] = {group, n, group - 1, n - 1};
    while (top > 0) {
        Task task = stack[--top];
        if (task.left > task.right) continue;
        usz middle = task.left + (task.right - task.left) / 2;
        usz upper = task.high < middle - 1 ? task.high : middle - 1;
        long best = INF;
        usz best_split = task.low;
        for (usz split = task.low; split <= upper; ++split) {
            if (previous[split] == INF) continue;
            long segment = prefix[middle] - prefix[split];
            long candidate = previous[split] + segment * segment;
            if (candidate < best) { best = candidate; best_split = split; }
        }
        current[middle] = best;
        if (middle < task.right) stack[top++] = {middle + 1, task.right, best_split, task.high};
        if (task.left < middle) stack[top++] = {task.left, middle - 1, task.low, best_split};
    }
}

fn long divide_conquer_dp_partition(long* values, usz length) @export("divide_conquer_dp_partition") {
    if (values == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = values[0], groups_value = values[1];
    if (n_value < 1 || n_value > (long)MAX_N || groups_value < 1 || groups_value > (long)MAX_GROUPS || groups_value > n_value || length != (usz)n_value + 2) return -1;
    usz n = (usz)n_value, groups = (usz)groups_value;
    long[MAX_N + 1] prefix = {}, first = {}, second = {};
    for (usz i = 0; i < n; ++i) {
        long value = values[i + 2];
        if (value < 0 || value > 1000) return -1;
        prefix[i + 1] = prefix[i] + value;
    }
    for (usz i = 0; i <= n; ++i) first[i] = INF;
    first[0] = 0;
    long* previous = &first[0]; long* current = &second[0];
    for (usz group = 1; group <= groups; ++group) {
        for (usz i = 0; i <= n; ++i) current[i] = INF;
        compute_row(previous, current, &prefix[0], n, group);
        long* temporary = previous; previous = current; current = temporary;
    }
    previous[n]
}
