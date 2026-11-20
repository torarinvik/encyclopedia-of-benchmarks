module lovasz_toggle_defective_coloring_trace;

const int MAX_N = 16;
const int MAX_M = 120;
const usz MAX_PARSEABLE_INPUT = 246;

fn long lovasz_toggle_defective_coloring_trace(long* input, usz length)
    @export("lovasz_toggle_defective_coloring_trace") {
    if (input == null || length < 5 || length > MAX_PARSEABLE_INPUT) return -1;
    long n64 = input[0], r64 = input[1], b64 = input[2];
    long red_mask = input[3], m64 = input[4];
    if (n64 < 0 || n64 > MAX_N || r64 < 1 || r64 > 8 || b64 < 1 || b64 > 8 ||
        m64 < 0 || m64 > MAX_M) return -1;
    int n = (int)n64, red_limit = (int)r64, blue_limit = (int)b64, m = (int)m64;
    long all_mask = ((long)1 << n) - 1;
    if (red_mask < 0 || (red_mask & ~all_mask) != 0 || length != 5 + 2 * (usz)m) return -1;

    bool[MAX_N][MAX_N] adjacent = {};
    int[MAX_N] degree = zeroed;
    for (int edge = 0; edge < m; edge += 1) {
        long u64 = input[5 + 2 * (usz)edge], v64 = input[6 + 2 * (usz)edge];
        if (u64 < 0 || u64 >= v64 || v64 >= n64) return -1;
        int u = (int)u64, v = (int)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = true; adjacent[v][u] = true;
        degree[u] += 1; degree[v] += 1;
        if (degree[u] > red_limit + blue_limit + 1 ||
            degree[v] > red_limit + blue_limit + 1) return -1;
    }

    int toggle_count = 0;
    while (true) {
        int bad = -1;
        for (int v = 0; v < n; v += 1) {
            int red_degree = 0;
            for (int u = 0; u < n; u += 1)
                if (adjacent[v][u] && ((red_mask >> u) & 1) != 0) red_degree += 1;
            int blue_degree = degree[v] - red_degree;
            bool is_red = ((red_mask >> v) & 1) != 0;
            if ((is_red && red_degree > red_limit) || (!is_red && blue_degree > blue_limit)) {
                bad = v;
                break;
            }
        }
        if (bad < 0) break;
        red_mask ^= (long)1 << bad;
        toggle_count += 1;
    }
    return ((long)toggle_count << n) | red_mask;
}
