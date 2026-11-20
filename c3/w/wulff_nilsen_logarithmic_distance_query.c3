module wulff_nilsen_logarithmic_distance_query;

const int K = 16, MAX_N = 8, MAX_M = 28, MAX_Q = 32;
const int MAX_INPUT = 167, MAX_NODES = 31, LOG_K = 4;
const long INF = 0x3fffffffffffffff;

struct IntervalNode {
    int lo, hi, mid, j, left, right;
}

fn void put_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn int build_node(IntervalNode[MAX_N][MAX_NODES]* trees, int[MAX_N]* counts,
                  long[MAX_N][MAX_N]* distance, int[K][MAX_N]* nearest,
                  int source, int lo, int hi) {
    int index = counts[source]++;
    if (index >= MAX_NODES) return -1;
    IntervalNode* node = &trees[source][index];
    node.lo = lo; node.hi = hi; node.mid = -1; node.j = -1; node.left = -1; node.right = -1;
    if (hi - lo <= LOG_K) return index;

    int mid = -1, best_mid_gap = 0x7fffffff;
    for (int candidate = lo + 2; candidate <= hi - 2; candidate += 2) {
        int gap = 2 * candidate - lo - hi;
        if (gap < 0) gap = -gap;
        if (gap < best_mid_gap) { best_mid_gap = gap; mid = candidate; }
    }
    if (mid < 0) return -1;
    int best_j = lo;
    long best_delta = distance[source][nearest[lo + 2][source]] - distance[source][nearest[lo][source]];
    for (int level = lo + 2; level <= mid - 2; level += 2) {
        long delta = distance[source][nearest[level + 2][source]] - distance[source][nearest[level][source]];
        if (delta > best_delta) { best_delta = delta; best_j = level; }
    }
    node.mid = mid; node.j = best_j;
    int left = build_node(trees, counts, distance, nearest, source, lo, best_j);
    int right = build_node(trees, counts, distance, nearest, source, mid, hi);
    if (left < 0 || right < 0) return -1;
    node.left = left; node.right = right;
    return index;
}

fn bool dist_k(long[MAX_N][MAX_N]* distance, int[K][MAX_N]* nearest,
              bool[MAX_N][MAX_N]* bunch, int n, int source, int target,
              int start, long* estimate, int* probes) {
    int level = start;
    while (level < K) {
        int pivot = nearest[level][source];
        (*probes)++;
        if (bunch[target][pivot]) {
            *estimate = distance[source][pivot] + distance[target][pivot];
            return true;
        }
        if (level + 1 >= K) return false;
        int temporary = source; source = target; target = temporary; level++;
        if (source < 0 || source >= n) return false;
    }
    return false;
}

fn long wulff_nilsen_logarithmic_distance_query(long* input, usz length,
    char* output, usz capacity) @export("wulff_nilsen_logarithmic_distance_query") {
    if (input == null || length < 18 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M) return -1;
    int n = n64.int(), m = m64.int();
    ulong valid_bits = (((ulong)1) << n) - 1;
    ulong[K] masks = zeroed;
    for (int level = 1; level < K; level++) {
        long raw = input[1 + level];
        if (raw <= 0 || (((ulong)raw) & ~valid_bits) != 0) return -1;
        masks[level] = (ulong)raw;
        if (level > 1 && (masks[level] & ~masks[level - 1]) != 0) return -1;
    }
    usz q_at = 17 + 3 * m.usz();
    if (q_at >= length || input[q_at] < 0 || input[q_at] > MAX_Q) return -1;
    int q = input[q_at].int();
    if (length != q_at + 1 + 2 * q.usz()) return -1;

    long[MAX_N][MAX_N] distance = zeroed;
    for (int i = 0; i < n; i++) for (int j = 0; j < n; j++) distance[i][j] = i == j ? 0 : INF;
    long previous_u = -1, previous_v = -1;
    for (int e = 0; e < m; e++) {
        long u64 = input[17 + 3 * e], v64 = input[18 + 3 * e], weight = input[19 + 3 * e];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 1 || weight > 1000) return -1;
        if (u64 < previous_u || (u64 == previous_u && v64 <= previous_v)) return -1;
        int u = u64.int(), v = v64.int(); previous_u = u64; previous_v = v64;
        distance[u][v] = weight; distance[v][u] = weight;
    }
    for (int k = 0; k < n; k++) for (int i = 0; i < n; i++) for (int j = 0; j < n; j++) {
        if (distance[i][k] != INF && distance[k][j] != INF && distance[i][k] + distance[k][j] < distance[i][j])
            distance[i][j] = distance[i][k] + distance[k][j];
    }
    for (int i = 0; i < n; i++) for (int j = 0; j < n; j++) if (distance[i][j] == INF) return -1;

    int[K][MAX_N] nearest = zeroed;
    for (int vertex = 0; vertex < n; vertex++) nearest[0][vertex] = vertex;
    for (int level = 1; level < K; level++) for (int vertex = 0; vertex < n; vertex++) {
        int best = -1;
        for (int candidate = 0; candidate < n; candidate++) if (((masks[level] >> candidate) & 1) != 0) {
            if (best < 0 || distance[vertex][candidate] < distance[vertex][best] ||
                (distance[vertex][candidate] == distance[vertex][best] && candidate < best)) best = candidate;
        }
        if (best < 0) return -1;
        nearest[level][vertex] = best;
    }

    bool[MAX_N][MAX_N] bunch = zeroed;
    for (int center = 0; center < n; center++) for (int level = 0; level < K; level++) {
        ulong current = level == 0 ? valid_bits : masks[level];
        ulong following = level + 1 == K ? 0 : masks[level + 1];
        long next_distance = INF;
        for (int candidate = 0; candidate < n; candidate++)
            if (((following >> candidate) & 1) != 0 && distance[center][candidate] < next_distance)
                next_distance = distance[center][candidate];
        for (int candidate = 0; candidate < n; candidate++) {
            bool in_current = ((current >> candidate) & 1) != 0;
            bool in_next = ((following >> candidate) & 1) != 0;
            if (in_current && !in_next && distance[center][candidate] < next_distance) bunch[center][candidate] = true;
        }
    }

    IntervalNode[MAX_N][MAX_NODES] trees = zeroed;
    int[MAX_N] counts = zeroed;
    for (int source = 0; source < n; source++)
        if (build_node(&trees, &counts, &distance, &nearest, source, 0, K - 1) < 0) return -1;

    long[1 + 2 * MAX_Q] staged = zeroed; staged[0] = q;
    for (int query = 0; query < q; query++) {
        long source64 = input[q_at + 1 + 2 * query], target64 = input[q_at + 2 + 2 * query];
        if (source64 < 0 || source64 >= n64 || target64 < 0 || target64 >= n64) return -1;
        int source = source64.int(), target = target64.int(), node_index = 0, probes = 0;
        if (source == target) {
            staged[1 + 2 * query] = 0;
            staged[2 + 2 * query] = 0;
            continue;
        }
        while (trees[source][node_index].hi - trees[source][node_index].lo > LOG_K) {
            IntervalNode node = trees[source][node_index];
            bool first = bunch[target][nearest[node.j][source]];
            bool second = bunch[source][nearest[node.j + 1][target]];
            probes += 2;
            node_index = !first && !second ? node.right : node.left;
        }
        long estimate = 0;
        if (!dist_k(&distance, &nearest, &bunch, n, source, target,
                    trees[source][node_index].lo, &estimate, &probes)) return -1;
        staged[1 + 2 * query] = estimate; staged[2 + 2 * query] = probes;
    }
    usz words = (1 + 2 * q).usz(), bytes = words * 8;
    if (output == null || capacity < bytes) return -2;
    for (usz i = 0; i < words; i++) put_i64(output, i * 8, staged[i]);
    return bytes.long();
}
