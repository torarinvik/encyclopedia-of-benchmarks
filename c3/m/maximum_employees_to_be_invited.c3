module maximum_employees_to_be_invited;

const usz MAX_N = 8, MAX_INPUT = 10;

fn long maximum_employees_to_be_invited(long* input, usz length)
        @export("maximum_employees_to_be_invited") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 2 || n_value > (long)MAX_N || length != (usz)(n_value + 1)) return -1;
    usz n = (usz)n_value;
    long[MAX_N] favorite = {};
    long[MAX_N] indegree = {};
    long[MAX_N] chain = {};
    usz[MAX_N] queue = {};
    bool[MAX_N] visited = {};
    for (usz i = 0; i < n; ++i) {
        long target = input[i + 1];
        if (target < 0 || target >= n_value || target == (long)i) return -1;
        favorite[i] = target;
        chain[i] = 1;
        indegree[target.usz()]++;
    }
    usz head = 0, tail = 0;
    for (usz i = 0; i < n; ++i) if (indegree[i] == 0) queue[tail++] = i;
    while (head < tail) {
        usz node = queue[head++];
        usz target = favorite[node].usz();
        if (chain[node] + 1 > chain[target]) chain[target] = chain[node] + 1;
        indegree[target]--;
        if (indegree[target] == 0) queue[tail++] = target;
    }
    long pair_total = 0, longest_cycle = 0;
    for (usz start = 0; start < n; ++start) {
        if (indegree[start] == 0 || visited[start]) continue;
        usz node = start, first = 0, second = 0;
        long cycle_length = 0;
        while (!visited[node]) {
            visited[node] = true;
            if (cycle_length == 0) first = node;
            else if (cycle_length == 1) second = node;
            cycle_length++;
            node = favorite[node].usz();
        }
        if (cycle_length == 2) pair_total += chain[first] + chain[second];
        else if (cycle_length > longest_cycle) longest_cycle = cycle_length;
    }
    return pair_total > longest_cycle ? pair_total : longest_cycle;
}
