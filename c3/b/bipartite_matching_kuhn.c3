module bipartite_matching_kuhn;

const usz MAX_SIDE = 64;
const usz MAX_EDGES = 4096;

fn bool try_augment(usz left, usz right_count, bool* adjacency, bool* seen_right,
                    int* pair_right) {
    for (usz right = 0; right < right_count; right++) {
        if (!adjacency[left * MAX_SIDE + right] || seen_right[right]) continue;
        seen_right[right] = true;
        int mate = pair_right[right];
        if (mate < 0 || try_augment((usz)mate, right_count, adjacency, seen_right, pair_right)) {
            pair_right[right] = (int)left;
            return true;
        }
    }
    return false;
}

// Return maximum matching cardinality, or -1 for malformed graph input.
fn long bipartite_matching_kuhn(long* input, usz length) @export("bipartite_matching_kuhn") {
    if (input == null || length < 3) return -1;
    if (input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 64 ||
        input[2] < 0 || input[2] > 4096) return -1;
    usz left_count = (usz)input[0], right_count = (usz)input[1], edge_count = (usz)input[2];
    if (length != 3 + 2 * edge_count) return -1;
    bool[4096] adjacency;
    for (usz edge = 0; edge < edge_count; edge++) {
        long left = input[3 + 2 * edge], right = input[4 + 2 * edge];
        if (left < 0 || left >= (long)left_count || right < 0 || right >= (long)right_count) return -1;
        adjacency[(usz)left * MAX_SIDE + (usz)right] = true;
    }
    int[64] pair_right;
    for (usz right = 0; right < right_count; right++) pair_right[right] = -1;
    long matching = 0;
    for (usz left = 0; left < left_count; left++) {
        bool[64] seen_right;
        for (usz right = 0; right < right_count; right++) seen_right[right] = false;
        if (try_augment(left, right_count, &adjacency[0], &seen_right[0], &pair_right[0])) matching++;
    }
    return matching;
}
