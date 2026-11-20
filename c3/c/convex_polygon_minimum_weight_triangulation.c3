module convex_polygon_minimum_weight_triangulation;

const usz MIN_N = 3;
const usz MAX_N = 10;
const usz MAX_LENGTH = 37;

fn long convex_polygon_minimum_weight_triangulation(long* input, usz length)
        @export("convex_polygon_minimum_weight_triangulation") {
    if (input == null || length < 1 || length > MAX_LENGTH) return -1;
    if (input[0] < 3 || input[0] > 10) return -1;
    usz n = (usz)input[0];
    usz diagonal_count = 0;
    for (usz i = 0; i < n; ++i) {
        for (usz j = i + 2; j < n; ++j) {
            if (!(i == 0 && j == n - 1)) ++diagonal_count;
        }
    }
    if (length != 1 + diagonal_count) return -1;

    long[10][10] weight = zeroed;
    usz at = 1;
    for (usz i = 0; i < n; ++i) {
        for (usz j = i + 2; j < n; ++j) {
            if (i == 0 && j == n - 1) continue;
            if (input[at] < 0 || input[at] > 1000) return -1;
            weight[i][j] = input[at];
            ++at;
        }
    }

    long[10][10] dp = zeroed;
    for (usz span = 2; span < n; ++span) {
        for (usz left = 0; left + span < n; ++left) {
            usz right = left + span;
            long best = 7001;
            for (usz split = left + 1; split < right; ++split) {
                long left_edge = if split - left == 1: 0 else: weight[left][split];
                long right_edge = if right - split == 1: 0 else: weight[split][right];
                long candidate = dp[left][split] + dp[split][right] + left_edge + right_edge;
                if (candidate < best) best = candidate;
            }
            dp[left][right] = best;
        }
    }
    return dp[0][n - 1];
}
