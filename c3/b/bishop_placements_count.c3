module bishop_placements_count;

const int MAX_N = 8;
const int MAX_K = 16;
const int MAX_DIAGONALS = 2 * MAX_N;

fn int diagonal_size(int index) {
    return (index & 1) != 0 ? (index / 4) * 2 + 1 : ((index - 1) / 4) * 2 + 2;
}

fn void color_counts(int k, int last_diagonal, long* out) {
    long[MAX_DIAGONALS * (MAX_K + 1)] dp = {};
    dp[0] = 1;
    dp[MAX_K + 1] = 1;
    if (k >= 1) dp[MAX_K + 2] = 1;
    for (int diagonal = 2; diagonal <= last_diagonal; diagonal++) {
        dp[diagonal * (MAX_K + 1)] = 1;
        int squares = diagonal_size(diagonal);
        for (int placed = 1; placed <= k; placed++) {
            dp[diagonal * (MAX_K + 1) + placed] =
                dp[(diagonal - 2) * (MAX_K + 1) + placed] +
                dp[(diagonal - 2) * (MAX_K + 1) + placed - 1] * (squares - placed + 1);
        }
    }
    for (int placed = 0; placed <= k; placed++)
        out[placed] = dp[last_diagonal * (MAX_K + 1) + placed];
}

fn long bishop_placements_count(long* input, usz length) @export("bishop_placements_count") {
    if (input == null || length != 2) return -1;
    if (input[0] < 1 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_K) return -1;
    int n = (int)input[0], k = (int)input[1];
    int maximum = n == 1 ? 1 : 2 * n - 2;
    if (k > maximum) return 0;
    long[MAX_K + 1] black = {}, white = {};
    color_counts(k, 2 * n - 1, &black[0]);
    color_counts(k, 2 * n - 2, &white[0]);
    long total = 0;
    for (int left = 0; left <= k; left++) total += black[left] * white[k - left];
    return total;
}
