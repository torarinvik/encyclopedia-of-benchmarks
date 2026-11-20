module dag_minimum_path_cover;

const usz MAX_N = 10;
const usz MAX_M = 45;
const usz MAX_PARSEABLE = 93;

fn bool dmpc_augment(usz left, usz n, uint used, uint* adjacency,
                     bool* seen, long* match_right) {
    for (usz right = 0; right < n; right += 1) {
        uint bit = (uint)1 << right;
        if ((adjacency[left] & bit) == 0 || (used & bit) != 0 || seen[right]) continue;
        seen[right] = true;
        long mate = match_right[right];
        if (mate < 0 || dmpc_augment(mate.usz(), n, used, adjacency, seen, match_right)) {
            match_right[right] = left.long();
            return true;
        }
    }
    return false;
}

fn usz dmpc_maximum(uint* adjacency, usz n, usz first, uint used) {
    long[MAX_N] match_right;
    for (usz right = 0; right < MAX_N; right += 1) match_right[right] = -1;
    usz size = 0;
    for (usz left = first; left < n; left += 1) {
        bool[MAX_N] seen = zeroed;
        if (dmpc_augment(left, n, used, adjacency, &seen[0], &match_right[0])) size += 1;
    }
    return size;
}

fn long dag_minimum_path_cover(long* input, usz length) @export("dag_minimum_path_cover") {
    if (input == null || length < 2 || length > MAX_PARSEABLE) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M) return -1;
    usz n = n_value.usz(), m = m_value.usz();
    if (length != 2 + 2 * m) return -1;

    uint[MAX_N] adjacency = zeroed;
    long[MAX_N] indegree = zeroed;
    for (usz edge = 0; edge < m; edge += 1) {
        long u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        usz u = u_value.usz(), v = v_value.usz();
        uint bit = (uint)1 << v;
        if ((adjacency[u] & bit) != 0) return -1;
        adjacency[u] |= bit;
        indegree[v] += 1;
    }
    usz[MAX_N] queue;
    usz head = 0, tail = 0, removed = 0;
    for (usz v = 0; v < n; v += 1) if (indegree[v] == 0) queue[tail++] = v;
    while (head < tail) {
        usz u = queue[head++];
        removed += 1;
        for (usz v = 0; v < n; v += 1) if ((adjacency[u] & ((uint)1 << v)) != 0) {
            indegree[v] -= 1;
            if (indegree[v] == 0) queue[tail++] = v;
        }
    }
    if (removed != n) return -1;

    usz maximum = dmpc_maximum(&adjacency[0], n, 0, 0);
    usz[MAX_N] successor;
    uint used = 0;
    usz fixed = 0;
    for (usz left = 0; left < n; left += 1) {
        bool chosen = false;
        for (usz right = 0; right <= n; right += 1) {
            bool matched = right < n;
            if (matched) {
                uint bit = (uint)1 << right;
                if ((adjacency[left] & bit) == 0 || (used & bit) != 0) continue;
            }
            uint next_used = matched ? used | ((uint)1 << right) : used;
            usz attainable = fixed + (matched ? 1 : 0) + dmpc_maximum(&adjacency[0], n, left + 1, next_used);
            if (attainable == maximum) {
                successor[left] = right;
                used = next_used;
                if (matched) fixed += 1;
                chosen = true;
                break;
            }
        }
        if (!chosen) return -1;
    }
    ulong packed = (n - maximum).ulong() << 40;
    for (usz v = 0; v < n; v += 1) packed |= successor[v].ulong() << (4 * v);
    return packed.long();
}
