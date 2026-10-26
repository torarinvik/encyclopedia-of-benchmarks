module approximate_matching_greedy;

struct Edge { usz u; usz v; long weight; bool used; }

fn void put_i64(uint8* output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[word * 8 + b] = (uint8)(bits >> (8 * b));
}

fn long approximate_matching_greedy(long* input, usz length, uint8* output, usz capacity) @export("approximate_matching_greedy") {
    if (input == null || length < 2 || length > 98) return -1;
    long n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 12 || m0 < 0 || m0 > 32 || length != (usz)(2 + 3 * m0)) return -1;
    usz m = (usz)m0;
    bool[12][12] seen;
    bool[12] matched;
    Edge[32] edges;
    for (usz i = 0; i < m; i++) {
        long u0 = input[2 + 3*i], v0 = input[3 + 3*i], weight = input[4 + 3*i];
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || weight < 1 || weight > 100) return -1;
        usz u = (usz)u0, v = (usz)v0;
        usz lo = u < v ? u : v, hi = u < v ? v : u;
        if (seen[lo][hi]) return -1;
        seen[lo][hi] = true; edges[i] = Edge{u, v, weight, false};
    }
    if (output == null || capacity < 16) return -2;
    long total = 0; ulong selected = 0;
    for (usz step = 0; step < m; step++) {
        usz best = m;
        for (usz i = 0; i < m; i++) if (!edges[i].used && (best == m || edges[i].weight > edges[best].weight)) best = i;
        edges[best].used = true;
        Edge edge = edges[best];
        if (!matched[edge.u] && !matched[edge.v]) {
            matched[edge.u] = true; matched[edge.v] = true;
            selected |= (ulong)1 << best; total += edge.weight;
        }
    }
    put_i64(output, 0, total); put_i64(output, 1, (long)selected);
    return 16;
}
