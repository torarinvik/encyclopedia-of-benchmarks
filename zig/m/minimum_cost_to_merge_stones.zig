const MAX_N: usize = 30;
const MAX_K: usize = 30;
const MAX_INPUT_LENGTH: usize = 33;
const DP_CELLS: usize = MAX_N * MAX_N * (MAX_K + 1);
const INFINITY: i64 = 1152921504606846976;

fn dpIndex(left: usize, right: usize, piles: usize) usize {
    return (left * MAX_N + right) * (MAX_K + 1) + piles;
}

export fn minimum_cost_to_merge_stones(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 or input[0] > MAX_N or input[1] < 2 or input[1] > MAX_K) return -1;
    const n: usize = @intCast(input[0]);
    const merge_count: usize = @intCast(input[1]);
    if (length != n + 2) return -1;

    var prefix = [_]i64{0} ** (MAX_N + 1);
    for (0..n) |i| {
        const stone = input[i + 2];
        if (stone < 1 or stone > 100) return -1;
        prefix[i + 1] = prefix[i] + stone;
    }
    if ((n - 1) % (merge_count - 1) != 0) return -1;

    var dp = [_]i64{INFINITY} ** DP_CELLS;
    for (0..n) |i| dp[dpIndex(i, i, 1)] = 0;
    for (2..n + 1) |interval_length| {
        for (0..n - interval_length + 1) |left| {
            const right = left + interval_length - 1;
            const maximum_piles = @min(merge_count, interval_length);
            for (2..maximum_piles + 1) |piles| {
                var best: i64 = INFINITY;
                for (left..right) |cut| {
                    const first = dp[dpIndex(left, cut, 1)];
                    const rest = dp[dpIndex(cut + 1, right, piles - 1)];
                    if (first < INFINITY and rest < INFINITY and first + rest < best)
                        best = first + rest;
                }
                dp[dpIndex(left, right, piles)] = best;
            }
            if (interval_length >= merge_count) {
                const to_k = dp[dpIndex(left, right, merge_count)];
                if (to_k < INFINITY)
                    dp[dpIndex(left, right, 1)] = to_k + prefix[right + 1] - prefix[left];
            }
        }
    }
    const answer = dp[dpIndex(0, n - 1, 1)];
    return if (answer >= INFINITY) -1 else answer;
}
