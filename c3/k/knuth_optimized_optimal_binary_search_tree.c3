module knuth_optimized_optimal_binary_search_tree;

const usz MAX_N = 64;
const long MAX_FREQUENCY = 1000000;

fn long knuth_optimized_optimal_binary_search_tree(long *v, usz n)
    @export("knuth_optimized_optimal_binary_search_tree") {
    if (v == null || n < 2 || n > 65 || v[0] < 1 || v[0] > (long)MAX_N || n != (usz)v[0] + 1) return -1;
    usz k = (usz)v[0];
    long[65] prefix; long[64][64] dp; usz[64][64] opt;
    for (usz i = 0; i < k; i++) {
        long f = v[i + 1]; if (f < 0 || f > MAX_FREQUENCY) return -1;
        prefix[i + 1] = prefix[i] + f; dp[i][i] = f; opt[i][i] = i;
    }
    for (usz width = 2; width <= k; width++) for (usz left = 0; left + width <= k; left++) {
        usz right = left + width - 1;
        usz first = opt[left][right - 1], last = opt[left + 1][right], best_root = first;
        long total = prefix[right + 1] - prefix[left], best = 0x7FFFFFFFFFFFFFFF;
        for (usz root = first; root <= last; root++) {
            long cost = total;
            if (root > left) cost += dp[left][root - 1];
            if (root < right) cost += dp[root + 1][right];
            if (cost < best) { best = cost; best_root = root; }
        }
        dp[left][right] = best; opt[left][right] = best_root;
    }
    return dp[0][k - 1];
}
