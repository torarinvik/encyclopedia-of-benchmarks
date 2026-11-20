module string_compression_ii;

const int MAX_N = 12, MAX_INPUT = 15, WIDTH = 13;
const long INF = 1000;

fn long run_cost(int kept) {
    if (kept == 1) return 1;
    int digits = 0;
    while (kept > 0) { digits += 1; kept /= 10; }
    return 1 + digits;
}

fn long string_compression_ii(long* input, usz length)
    @export("string_compression_ii") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long raw_n = input[0], raw_k = input[1];
    if (raw_n < 0 || raw_n > MAX_N || raw_k < 0 || raw_k > raw_n) return -1;
    int n = (int)raw_n, budget = (int)raw_k;
    if (length != (usz)(n + 2)) return -1;
    for (int i = 0; i < n; i += 1) if (input[i + 2] < 0 || input[i + 2] > 25) return -1;

    long[WIDTH][WIDTH] dp = zeroed;
    for (int i = 0; i < WIDTH; i += 1)
        for (int d = 0; d < WIDTH; d += 1) dp[i][d] = INF;
    dp[0][0] = 0;

    for (int start = 0; start < n; start += 1) {
        for (int used = 0; used <= budget; used += 1) {
            long prefix_cost = dp[start][used];
            if (prefix_cost == INF) continue;
            if (used < budget && prefix_cost < dp[start + 1][used + 1])
                dp[start + 1][used + 1] = prefix_cost;
            int same = 0;
            for (int end = start; end < n; end += 1) {
                if (input[end + 2] == input[start + 2]) same += 1;
                int span = end - start + 1;
                for (int kept = 1; kept <= same; kept += 1) {
                    int total_deleted = used + span - kept;
                    if (total_deleted > budget) continue;
                    long candidate = prefix_cost + run_cost(kept);
                    if (candidate < dp[end + 1][total_deleted]) dp[end + 1][total_deleted] = candidate;
                }
            }
        }
    }
    long answer = INF;
    for (int d = 0; d <= budget; d += 1) if (dp[n][d] < answer) answer = dp[n][d];
    return answer;
}
