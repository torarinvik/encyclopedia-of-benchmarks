module redundant_directed_connection_repair;

const usz MAX_N = 16;
const usz MAX_PARSEABLE_LENGTH = 34;

fn usz repair_find(usz* parent, usz node) {
    while (parent[node] != node) { parent[node] = parent[parent[node]]; node = parent[node]; }
    return node;
}

fn long redundant_directed_connection_repair(long* input, usz length)
        @export("redundant_directed_connection_repair") {
    if (input == null || length == 0 || length > MAX_PARSEABLE_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 3 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * n) return -1;
    usz[MAX_N] from, to, incoming, parent, sizes;
    for (usz node = 0; node < n; node++) { incoming[node] = MAX_N; parent[node] = node; sizes[node] = 1; }
    for (usz edge = 0; edge < n; edge++) {
        long u_value = input[1 + 2 * edge], v_value = input[2 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value)
            return -1;
        from[edge] = (usz)u_value;
        to[edge] = (usz)v_value;
        for (usz prior = 0; prior < edge; prior++)
            if (from[prior] == from[edge] && to[prior] == to[edge]) return -1;
    }
    long first_parent = -1, second_parent = -1;
    for (usz edge = 0; edge < n; edge++) {
        usz child = to[edge];
        if (incoming[child] == MAX_N) incoming[child] = edge;
        else { first_parent = (long)incoming[child]; second_parent = (long)edge; break; }
    }
    long cycle_edge = -1;
    for (usz edge = 0; edge < n; edge++) {
        if ((long)edge == second_parent) continue;
        usz a = repair_find(&parent[0], from[edge]);
        usz b = repair_find(&parent[0], to[edge]);
        if (a == b) { cycle_edge = (long)edge; break; }
        if (sizes[a] < sizes[b]) { usz swap = a; a = b; b = swap; }
        parent[b] = a;
        sizes[a] += sizes[b];
    }
    if (cycle_edge >= 0) return second_parent >= 0 ? first_parent : cycle_edge;
    return second_parent;
}
