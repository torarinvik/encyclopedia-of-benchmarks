module minimum_cost_to_merge_stones;

const usz MAX_N = 30;
const usz MAX_K = 30;
const usz MAX_PARSEABLE_INPUT_LENGTH = 33;
const usz DP_CELLS = MAX_N * MAX_N * (MAX_K + 1);

fn usz dp_index(usz left, usz right, usz piles) {
    return (left * MAX_N + right) * (MAX_K + 1) + piles;
}

fn long minimum_cost_to_merge_stones(long* input, usz length)
    @export("minimum_cost_to_merge_stones") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 2 || input[1] > (long)MAX_K) return -1;
    usz n = (usz)input[0], merge_count = (usz)input[1];
    if (length != n + 2) return -1;

    long[MAX_N + 1] prefix = zeroed;
    for (usz i = 0; i < n; i++) {
        long stone = input[i + 2];
        if (stone < 1 || stone > 100) return -1;
        prefix[i + 1] = prefix[i] + stone;
    }
    if ((n - 1) % (merge_count - 1) != 0) return -1;

    long infinity = 0x1FFFFFFFFFFFFFFF;
    long[DP_CELLS] dp;
    for (usz i = 0; i < DP_CELLS; i++) dp[i] = infinity;
    for (usz i = 0; i < n; i++) dp[dp_index(i, i, 1)] = 0;

    for (usz interval_length = 2; interval_length <= n; interval_length++) {
        for (usz left = 0; left + interval_length <= n; left++) {
            usz right = left + interval_length - 1;
            usz maximum_piles = if merge_count < interval_length: merge_count else: interval_length;
            for (usz piles = 2; piles <= maximum_piles; piles++) {
                long best = infinity;
                for (usz cut = left; cut < right; cut++) {
                    long first = dp[dp_index(left, cut, 1)];
                    long rest = dp[dp_index(cut + 1, right, piles - 1)];
                    if (first < infinity && rest < infinity && first + rest < best)
                        best = first + rest;
                }
                dp[dp_index(left, right, piles)] = best;
            }
            if (interval_length >= merge_count) {
                long to_k = dp[dp_index(left, right, merge_count)];
                if (to_k < infinity)
                    dp[dp_index(left, right, 1)] = to_k + prefix[right + 1] - prefix[left];
            }
        }
    }
    long answer = dp[dp_index(0, n - 1, 1)];
    return if answer >= infinity: -1 else: answer;
}
