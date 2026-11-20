module monge_dag_fixed_edge_shortest_path;

const usz MAX_N = 32;
const usz SIDE = 33;
const usz MAX_INPUT = 531;
const usz MAX_FRAMES = 64;
const long INF = 1152921504606846976l;

fn void monge_layer(usz n, usz layer, long* dp, long* cost, long* next) {
    usz[MAX_FRAMES] row_begin = {}, row_end = {}, col_begin = {}, col_end = {};
    usz top = 1;
    row_begin[0] = layer; row_end[0] = n + 1;
    col_begin[0] = layer - 1; col_end[0] = n;
    while (top > 0) {
        top--;
        usz rb = row_begin[top], re = row_end[top], cb = col_begin[top], ce = col_end[top];
        if (rb >= re) continue;
        usz row = (rb + re) / 2;
        usz upper = ce < row ? ce : row;
        usz best_column = cb;
        long best_value = INF;
        for (usz column = cb; column < upper; column++) {
            if (dp[column] == INF) continue;
            long candidate = dp[column] + cost[column * SIDE + row];
            if (candidate < best_value) { best_value = candidate; best_column = column; }
        }
        next[row] = best_value;
        if (row + 1 < re && best_column < ce) {
            row_begin[top] = row + 1; row_end[top] = re;
            col_begin[top] = best_column; col_end[top] = ce; top++;
        }
        if (rb < row && cb <= best_column) {
            row_begin[top] = rb; row_end[top] = row;
            col_begin[top] = cb; col_end[top] = best_column + 1; top++;
        }
    }
}

fn long monge_dag_fixed_edge_shortest_path(long* input, usz length)
        @export("monge_dag_fixed_edge_shortest_path") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n0 = input[0], d0 = input[1];
    if (n0 < 1 || n0 > 32 || d0 < 1 || d0 > n0) return -1;
    usz n = (usz)n0, layers = (usz)d0;
    if (length != 2 + n * (n + 1) / 2) return -1;

    long[SIDE * SIDE] cost = {};
    usz offset = 2;
    for (usz u = 0; u < n; u++) {
        for (usz v = u + 1; v <= n; v++) {
            long weight = input[offset++];
            if (weight < 0 || weight > 1000000) return -1;
            cost[u * SIDE + v] = weight;
        }
    }
    for (usz u = 0; u + 1 < n; u++) {
        for (usz v = u + 2; v < n; v++) {
            if (cost[u * SIDE + v] + cost[(u + 1) * SIDE + v + 1] >
                cost[u * SIDE + v + 1] + cost[(u + 1) * SIDE + v]) return -1;
        }
    }

    long[SIDE] dp = {}, next = {};
    for (usz v = 0; v <= n; v++) dp[v] = INF;
    dp[0] = 0;
    for (usz layer = 1; layer <= layers; layer++) {
        for (usz v = 0; v <= n; v++) next[v] = INF;
        monge_layer(n, layer, &dp[0], &cost[0], &next[0]);
        for (usz v = 0; v <= n; v++) dp[v] = next[v];
    }
    return dp[n];
}
