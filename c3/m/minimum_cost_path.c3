module minimum_cost_path;

const long INVALID_RESULT = (-9223372036854775807L - 1L);
const usz MAX_DIM = 16;

fn long minimum_cost_path(long* values, usz length) @export("minimum_cost_path") {
    if (values == null || length < 3) return INVALID_RESULT;
    long rv = values[0], cv = values[1];
    if (rv < 1 || rv > 16 || cv < 1 || cv > 16) return INVALID_RESULT;
    usz rows = (usz)rv, cols = (usz)cv;
    if (length != 2 + rows * cols) return INVALID_RESULT;
    long dp[16][16];
    for (usz r = 0; r < rows; r++) for (usz c = 0; c < cols; c++) {
        long x = values[2 + r * cols + c];
        if (x < -2147483648L || x > 2147483647L) return INVALID_RESULT;
        dp[r][c] = x;
    }
    for (usz c = 1; c < cols; c++) dp[0][c] += dp[0][c - 1];
    for (usz r = 1; r < rows; r++) dp[r][0] += dp[r - 1][0];
    for (usz r = 1; r < rows; r++) for (usz c = 1; c < cols; c++) {
        long prev = dp[r - 1][c] < dp[r][c - 1] ? dp[r - 1][c] : dp[r][c - 1];
        dp[r][c] += prev;
    }
    return dp[rows - 1][cols - 1];
}
