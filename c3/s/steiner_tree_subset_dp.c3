module steiner_tree_subset_dp;

const usz MAX_N = 8;
const usz MAX_M = 14;
const usz MAX_K = 5;
const usz MAX_INPUT = 50;
const usz MAX_MASKS = 1 << MAX_K;
const long INF = 1000000000000000000;

fn long steiner_tree_subset_dp(long* input, usz length) @export("steiner_tree_subset_dp") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1], k0 = input[2];
    if (n0 < 1 || n0 > 8 || m0 < 0 || m0 > 14 || k0 < 1 || k0 > 5 || k0 > n0) return -1;
    usz n = (usz)n0, m = (usz)m0, k = (usz)k0;
    if (m > n * (n - 1) / 2 || length != 3 + k + 3 * m) return -1;

    bool[MAX_N] terminal_seen = {};
    usz[MAX_K] terminals = {};
    for (usz i = 0; i < k; i++) {
        long raw = input[3 + i];
        if (raw < 0 || raw >= n0 || terminal_seen[(usz)raw]) return -1;
        terminal_seen[(usz)raw] = true;
        terminals[i] = (usz)raw;
    }

    bool[MAX_N * MAX_N] present = {};
    long[MAX_N * MAX_N] weights = {};
    for (usz i = 0; i < m; i++) {
        long ru = input[3 + k + 3 * i], rv = input[4 + k + 3 * i], w = input[5 + k + 3 * i];
        if (ru < 0 || ru >= rv || rv >= n0 || w < 0 || w > 1000) return -1;
        usz u = (usz)ru, v = (usz)rv;
        if (present[u * MAX_N + v]) return -1;
        present[u * MAX_N + v] = true;
        present[v * MAX_N + u] = true;
        weights[u * MAX_N + v] = w;
        weights[v * MAX_N + u] = w;
    }

    long[MAX_MASKS * MAX_N] dp = {};
    for (usz i = 0; i < MAX_MASKS * MAX_N; i++) dp[i] = INF;
    for (usz bit = 0; bit < k; bit++) dp[(1 << bit) * MAX_N + terminals[bit]] = 0;
    usz masks = 1 << k;
    for (usz mask = 1; mask < masks; mask++) {
        if ((mask & (mask - 1)) != 0) {
            usz sub = (mask - 1) & mask;
            while (sub != 0) {
                usz other = mask ^ sub;
                if (sub < other) {
                    for (usz v = 0; v < n; v++) {
                        long left = dp[sub * MAX_N + v], right = dp[other * MAX_N + v];
                        if (left < INF && right < INF && left + right < dp[mask * MAX_N + v]) dp[mask * MAX_N + v] = left + right;
                    }
                }
                sub = (sub - 1) & mask;
            }
        }
        bool[MAX_N] used = {};
        for (usz step = 0; step < n; step++) {
            usz chosen = n;
            for (usz v = 0; v < n; v++)
                if (!used[v] && (chosen == n || dp[mask * MAX_N + v] < dp[mask * MAX_N + chosen])) chosen = v;
            if (chosen == n || dp[mask * MAX_N + chosen] >= INF) break;
            used[chosen] = true;
            for (usz v = 0; v < n; v++) {
                usz edge = chosen * MAX_N + v;
                if (present[edge] && !used[v]) {
                    long candidate = dp[mask * MAX_N + chosen] + weights[edge];
                    if (candidate < dp[mask * MAX_N + v]) dp[mask * MAX_N + v] = candidate;
                }
            }
        }
    }
    long answer = INF;
    for (usz v = 0; v < n; v++) if (dp[(masks - 1) * MAX_N + v] < answer) answer = dp[(masks - 1) * MAX_N + v];
    return answer >= INF ? -2 : answer;
}
