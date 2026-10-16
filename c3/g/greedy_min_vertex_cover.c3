module greedy_min_vertex_cover;

const int MAX_VERTICES = 16;

fn int bit_count(ulong value) {
    int count = 0;
    while (value != 0) { value &= value - 1; count++; }
    return count;
}

fn long greedy_min_vertex_cover(long* values, usz length) @export("greedy_min_vertex_cover") {
    if (values == null || length < 2 || length > MAX_VERTICES + 1) return -1;
    long count_value = values[0];
    if (count_value < 1 || count_value > MAX_VERTICES || length != (usz)count_value + 1) return -1;
    int count = (int)count_value;
    ulong limit = ((ulong)1 << count) - 1;
    ulong[MAX_VERTICES] neighbors;
    for (int vertex = 0; vertex < count; vertex++) {
        long mask_value = values[vertex + 1];
        if (mask_value < 0 || (ulong)mask_value > limit) return -1;
        ulong mask = (ulong)mask_value;
        if ((mask & ((ulong)1 << vertex)) != 0) return -1;
        neighbors[vertex] = mask;
    }
    for (int vertex = 0; vertex < count; vertex++)
        for (int other = vertex + 1; other < count; other++)
            if (((neighbors[vertex] >> other) & 1) != ((neighbors[other] >> vertex) & 1)) return -1;

    ulong chosen = 0;
    while (true) {
        int best_vertex = -1, best_degree = 0;
        for (int vertex = 0; vertex < count; vertex++) {
            int degree = bit_count(neighbors[vertex]);
            if (degree > best_degree) { best_vertex = vertex; best_degree = degree; }
        }
        if (best_vertex < 0) return (long)chosen;
        ulong bit = (ulong)1 << best_vertex;
        chosen |= bit;
        for (int vertex = 0; vertex < count; vertex++) neighbors[vertex] &= ~bit;
        neighbors[best_vertex] = 0;
    }
}
