module bipartite_matching_hopcroft_karp;

const usz MAX_SIDE = 64;
const usz MAX_EDGES = 4096;
const int INF_DISTANCE = 1000000;

fn bool dfs_augment(usz left, usz right_count, bool* adjacency, int* distance,
                   int nil_distance, int* pair_left, int* pair_right) {
    for (usz right = 0; right < right_count; right++) {
        if (!adjacency[left * MAX_SIDE + right]) continue;
        int mate = pair_right[right];
        if (mate < 0) {
            if (distance[left] + 1 != nil_distance) continue;
            pair_left[left] = (int)right;
            pair_right[right] = (int)left;
            return true;
        }
        usz mate_index = (usz)mate;
        if (distance[mate_index] == distance[left] + 1 &&
            dfs_augment(mate_index, right_count, adjacency, distance, nil_distance, pair_left, pair_right)) {
            pair_left[left] = (int)right;
            pair_right[right] = (int)left;
            return true;
        }
    }
    distance[left] = INF_DISTANCE;
    return false;
}

fn int bfs_layers(usz left_count, usz right_count, bool* adjacency,
                  int* pair_right, int* distance) {
    usz[64] queue;
    usz head = 0, tail = 0;
    for (usz left = 0; left < left_count; left++) {
        if (distance[left] == 0) queue[tail++] = left;
    }
    int nil_distance = INF_DISTANCE;
    while (head < tail) {
        usz left = queue[head++];
        if (distance[left] + 1 > nil_distance) continue;
        for (usz right = 0; right < right_count; right++) {
            if (!adjacency[left * MAX_SIDE + right]) continue;
            int mate = pair_right[right];
            if (mate < 0) {
                if (distance[left] + 1 < nil_distance) nil_distance = distance[left] + 1;
            } else {
                usz mate_index = (usz)mate;
                if (distance[mate_index] < 0) {
                    distance[mate_index] = distance[left] + 1;
                    queue[tail++] = mate_index;
                }
            }
        }
    }
    return nil_distance;
}

// Return maximum matching cardinality, or -1 for malformed graph input.
fn long bipartite_matching_hopcroft_karp(long* input, usz length) @export("bipartite_matching_hopcroft_karp") {
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
    int[64] pair_left, pair_right, distance;
    for (usz left = 0; left < left_count; left++) pair_left[left] = -1;
    for (usz right = 0; right < right_count; right++) pair_right[right] = -1;
    long matching = 0;
    while (true) {
        for (usz left = 0; left < left_count; left++) distance[left] = pair_left[left] < 0 ? 0 : -1;
        int nil_distance = bfs_layers(left_count, right_count, &adjacency[0], &pair_right[0], &distance[0]);
        if (nil_distance == INF_DISTANCE) break;
        for (usz left = 0; left < left_count; left++) {
            if (pair_left[left] < 0 && dfs_augment(left, right_count, &adjacency[0], &distance[0], nil_distance,
                                                   &pair_left[0], &pair_right[0])) matching++;
        }
    }
    return matching;
}
