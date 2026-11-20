module reverse_delete_mst;

const usz MAX_N = 8;
const usz MAX_M = 20;
const usz MAX_INPUT = 63;

struct Edge { long u; long v; long weight; }

fn bool graph_connected(usz n, Edge[MAX_M] edges, usz m, uint active) {
    bool[MAX_N] seen = {};
    usz[MAX_N] queue = {};
    usz head = 0, tail = 1;
    seen[0] = true;
    queue[0] = 0;
    while (head < tail) {
        usz vertex = queue[head++];
        for (usz id = 0; id < m; id++) {
            if (((active >> id) & 1) == 0) continue;
            long neighbor = -1;
            if (edges[id].u == (long)vertex) neighbor = edges[id].v;
            else if (edges[id].v == (long)vertex) neighbor = edges[id].u;
            if (neighbor >= 0 && !seen[(usz)neighbor]) {
                seen[(usz)neighbor] = true;
                queue[tail++] = (usz)neighbor;
            }
        }
    }
    for (usz vertex = 0; vertex < n; vertex++) if (!seen[vertex]) return false;
    return true;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long reverse_delete_mst(long* input, usz length, char* output, usz capacity)
    @export("reverse_delete_mst") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_word = input[0], m_word = input[1];
    if (n_word < 2 || n_word > (long)MAX_N || m_word < n_word - 1 || m_word > (long)MAX_M) return -1;
    usz n = (usz)n_word, m = (usz)m_word;
    if (length != 2 + 3 * m) return -1;
    Edge[MAX_M] edges = {};
    usz[MAX_M] order = {};
    for (usz id = 0; id < m; id++) {
        long u = input[2 + 3 * id], v = input[3 + 3 * id], weight = input[4 + 3 * id];
        if (u < 0 || u >= (long)n || v < 0 || v >= (long)n || u == v || weight < 0 || weight > 1000) return -1;
        edges[id] = {u, v, weight};
        order[id] = id;
        long low = u < v ? u : v;
        long high = u < v ? v : u;
        for (usz prior = 0; prior < id; prior++) {
            long prior_low = edges[prior].u < edges[prior].v ? edges[prior].u : edges[prior].v;
            long prior_high = edges[prior].u < edges[prior].v ? edges[prior].v : edges[prior].u;
            if (low == prior_low && high == prior_high) return -1;
        }
    }
    for (usz i = 1; i < m; i++) {
        usz item = order[i], j = i;
        while (j > 0 && (edges[order[j - 1]].weight < edges[item].weight ||
                (edges[order[j - 1]].weight == edges[item].weight && order[j - 1] < item))) {
            order[j] = order[j - 1];
            j--;
        }
        order[j] = item;
    }
    uint active = (1u << m) - 1u;
    if (!graph_connected(n, edges, m, active)) return -1;
    for (usz position = 0; position < m; position++) {
        uint candidate = active & ~(1u << order[position]);
        if (graph_connected(n, edges, m, candidate)) active = candidate;
    }
    long total_weight = 0;
    for (usz id = 0; id < m; id++) if ((active >> id) & 1) total_weight += edges[id].weight;
    if (output == null || capacity < 16) return -2;
    store_i64_le(output, 0, (long)active);
    store_i64_le(output, 8, total_weight);
    return 16;
}
