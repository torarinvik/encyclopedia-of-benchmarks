module dulmage_mendelsohn_decomposition;

const usz SIDE = 6, VERTICES = 12, EDGES = 36, MAX_PARSEABLE = 76;

fn bool dm_augment(usz left, usz right_count, uint* adjacency,
                   bool* seen, long* match_right) {
    for (usz right = 0; right < right_count; right += 1) {
        uint bit = (uint)1 << right;
        if ((adjacency[left] & bit) == 0 || seen[right]) continue;
        seen[right] = true;
        long mate = match_right[right];
        if (mate < 0 || dm_augment(mate.usz(), right_count, adjacency, seen, match_right)) {
            match_right[right] = left.long();
            return true;
        }
    }
    return false;
}

fn usz dm_matching(usz left_count, usz right_count, uint* adjacency,
                   long* match_left, long* match_right) {
    for (usz right = 0; right < SIDE; right += 1) match_right[right] = -1;
    usz size = 0;
    for (usz left = 0; left < left_count; left += 1) {
        bool[SIDE] seen = zeroed;
        if (dm_augment(left, right_count, adjacency, &seen[0], match_right)) size += 1;
    }
    for (usz left = 0; left < SIDE; left += 1) match_left[left] = -1;
    for (usz right = 0; right < right_count; right += 1)
        if (match_right[right] >= 0) match_left[match_right[right].usz()] = right.long();
    return size;
}

fn long dulmage_mendelsohn_decomposition(long* input, usz length) @export("dulmage_mendelsohn_decomposition") {
    if (input == null || length < 3 || length > MAX_PARSEABLE) return -1;
    long left_value = input[0], right_value = input[1], edge_value = input[2];
    if (left_value < 0 || left_value > SIDE.long() || right_value < 0 || right_value > SIDE.long() ||
        left_value + right_value < 1 || edge_value < 0 || edge_value > EDGES.long() ||
        edge_value > left_value * right_value) return -1;
    usz left_count = left_value.usz(), right_count = right_value.usz(), edge_count = edge_value.usz();
    usz total = left_count + right_count;
    if (length != 3 + 2 * edge_count) return -1;
    uint[SIDE] adjacency = zeroed;
    uint[VERTICES] global = zeroed;
    for (usz edge = 0; edge < edge_count; edge += 1) {
        long u_value = input[3 + 2 * edge], v_value = input[4 + 2 * edge];
        if (u_value < 0 || u_value >= left_value || v_value < 0 || v_value >= right_value) return -1;
        usz u = u_value.usz(), v = v_value.usz(), right_vertex = left_count + v;
        uint bit = (uint)1 << v;
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit;
        global[u] |= (uint)1 << right_vertex;
        global[right_vertex] |= (uint)1 << u;
    }
    long[SIDE] match_left, match_right;
    usz matching_size = dm_matching(left_count, right_count, &adjacency[0], &match_left[0], &match_right[0]);
    bool[2 * VERTICES] seen = zeroed;
    usz[2 * VERTICES] queue;
    usz head = 0, tail = 0;
    for (usz left = 0; left < left_count; left += 1) if (match_left[left] < 0) {
        usz state = 2 * left; seen[state] = true; queue[tail++] = state;
    }
    for (usz right = 0; right < right_count; right += 1) if (match_right[right] < 0) {
        usz state = 2 * (left_count + right); seen[state] = true; queue[tail++] = state;
    }
    while (head < tail) {
        usz state = queue[head++], vertex = state / 2, parity = state & 1;
        for (usz neighbor = 0; neighbor < total; neighbor += 1) {
            if ((global[vertex] & ((uint)1 << neighbor)) == 0) continue;
            bool matched = vertex < left_count ? match_left[vertex] == neighbor.long() - left_count.long()
                                                : match_right[vertex - left_count] == neighbor.long();
            if ((parity == 0 && matched) || (parity == 1 && !matched)) continue;
            usz next_state = 2 * neighbor + 1 - parity;
            if (!seen[next_state]) { seen[next_state] = true; queue[tail++] = next_state; }
        }
    }
    ulong packed = matching_size.ulong() << 32;
    for (usz vertex = 0; vertex < total; vertex += 1) {
        ulong code = if seen[2 * vertex]: 0 else if seen[2 * vertex + 1]: 1 else: 2;
        packed |= code << (2 * vertex);
    }
    return packed.long();
}
