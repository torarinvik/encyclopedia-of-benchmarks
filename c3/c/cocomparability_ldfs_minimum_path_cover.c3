module cocomparability_ldfs_minimum_path_cover;
import "core:c";

const usz MAX_N = 8;
const usz MAX_PARSEABLE = 18;

fn long cocomparability_ldfs_minimum_path_cover(long* input, usz length)
    @export("cocomparability_ldfs_minimum_path_cover") {
    if (input == null || length < 1 || length > MAX_PARSEABLE) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N || length != 1 + 2 * n_value.usz()) return -1;
    usz n = n_value.usz();
    uint full = ((uint)1 << n) - 1;
    uint[MAX_N] adjacency = zeroed;
    usz[MAX_N] order, rank, position;
    bool[MAX_N] seen_order = zeroed;
    for (usz v = 0; v < n; v += 1) {
        long row = input[1 + v];
        if (row < 0 || row > (long)full || (row & (1 << v.long())) != 0) return -1;
        adjacency[v] = row.uint();
    }
    for (usz u = 0; u < n; u += 1) {
        for (usz v = 0; v < n; v += 1) {
            if (((adjacency[u] >> v) & 1) != ((adjacency[v] >> u) & 1)) return -1;
        }
    }
    for (usz i = 0; i < n; i += 1) {
        long value = input[1 + n + i];
        if (value < 0 || value >= n_value || seen_order[value.usz()]) return -1;
        order[i] = value.usz();
        rank[value.usz()] = i;
        seen_order[value.usz()] = true;
    }
    for (usz i = 0; i < n; i += 1) {
        for (usz j = i + 1; j < n; j += 1) {
            for (usz k = j + 1; k < n; k += 1) {
                usz a = order[i], b = order[j], c = order[k];
                if (((adjacency[a] >> c) & 1) != 0 &&
                    ((adjacency[a] >> b) & 1) == 0 &&
                    ((adjacency[b] >> c) & 1) == 0) return -1;
            }
        }
    }
    bool[MAX_N] reached = zeroed;
    usz[MAX_N] queue;
    usz head = 0, tail = 0;
    queue[tail++] = 0;
    reached[0] = true;
    while (head < tail) {
        usz u = queue[head++];
        for (usz v = 0; v < n; v += 1) {
            if (((adjacency[u] >> v) & 1) != 0 && !reached[v]) {
                reached[v] = true;
                queue[tail++] = v;
            }
        }
    }
    for (usz v = 0; v < n; v += 1) if (!reached[v]) return -1;

    u8[MAX_N][MAX_N] labels = zeroed;
    usz[MAX_N] label_len = zeroed;
    bool[MAX_N] visited = zeroed;
    usz[MAX_N] ldfs;
    for (usz step = 1; step <= n; step += 1) {
        usz chosen = MAX_N;
        for (usz v = 0; v < n; v += 1) {
            if (visited[v]) continue;
            if (chosen == MAX_N) { chosen = v; continue; }
            usz common = label_len[v] < label_len[chosen] ? label_len[v] : label_len[chosen];
            int cmp = 0;
            for (usz i = 0; i < common; i += 1) {
                if (labels[v][i] != labels[chosen][i]) {
                    cmp = labels[v][i] > labels[chosen][i] ? 1 : -1;
                    break;
                }
            }
            if (cmp == 0 && label_len[v] != label_len[chosen])
                cmp = label_len[v] > label_len[chosen] ? 1 : -1;
            if (cmp > 0 || (cmp == 0 && rank[v] > rank[chosen])) chosen = v;
        }
        ldfs[step - 1] = chosen;
        visited[chosen] = true;
        for (usz v = 0; v < n; v += 1) {
            if (!visited[v] && ((adjacency[chosen] >> v) & 1) != 0) {
                usz i = label_len[v];
                while (i > 0) { labels[v][i] = labels[v][i - 1]; i -= 1; }
                labels[v][0] = step.u8();
                label_len[v] += 1;
            }
        }
    }
    for (usz i = 0; i < n; i += 1) position[ldfs[i]] = i;

    for (usz v = 0; v < n; v += 1) visited[v] = false;
    usz paths = 0;
    while (true) {
        usz current = MAX_N;
        for (usz v = 0; v < n; v += 1)
            if (!visited[v] && (current == MAX_N || position[v] > position[current])) current = v;
        if (current == MAX_N) break;
        paths += 1;
        visited[current] = true;
        while (true) {
            usz next = MAX_N;
            for (usz v = 0; v < n; v += 1)
                if (!visited[v] && ((adjacency[current] >> v) & 1) != 0 &&
                    (next == MAX_N || position[v] > position[next])) next = v;
            if (next == MAX_N) break;
            visited[next] = true;
            current = next;
        }
    }
    return paths.long();
}
