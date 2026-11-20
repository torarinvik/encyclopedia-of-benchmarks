module minimum_cost_bipartite_edge_cover_subset_dp;

const long INF = (long)1 << 60;

fn long minimum_cost_bipartite_edge_cover_subset_dp(long* input, usz length)
    @export("minimum_cost_bipartite_edge_cover_subset_dp") {
    if (input == null || length < 2 || length > 67) return -1;
    long left_count = input[0];
    long right_count = input[1];
    if (left_count < 1 || left_count > 8 || right_count < 1 || right_count > 8) return -1;
    if (length != (usz)(2 + left_count * right_count)) return -1;
    for (usz edge = 0; edge < (usz)(left_count * right_count); edge++) {
        long cost = input[2 + edge];
        if (cost < 0 || cost > 1000) return -1;
    }

    usz states = (usz)1 << (usz)right_count;
    long[256] current;
    long[256] following;
    long[256] subset_cost;
    for (usz mask = 0; mask < states; mask++) current[mask] = INF;
    current[0] = 0;
    for (usz left = 0; left < (usz)left_count; left++) {
        subset_cost[0] = 0;
        for (usz subset = 1; subset < states; subset++) {
            usz bit = subset & (~subset + 1);
            usz right = 0;
            while (((bit >> right) & 1) == 0) right++;
            subset_cost[subset] = subset_cost[subset ^ bit] + input[2 + left * (usz)right_count + right];
        }
        for (usz mask = 0; mask < states; mask++) following[mask] = INF;
        for (usz covered = 0; covered < states; covered++) {
            if (current[covered] == INF) continue;
            for (usz selected = 1; selected < states; selected++) {
                usz combined = covered | selected;
                long candidate = current[covered] + subset_cost[selected];
                if (candidate < following[combined]) following[combined] = candidate;
            }
        }
        for (usz mask = 0; mask < states; mask++) current[mask] = following[mask];
    }
    return current[states - 1];
}
