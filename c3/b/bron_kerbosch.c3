module bron_kerbosch;

fn ulong population_count(ulong value) {
    ulong bits = value;
    ulong count = 0;
    while (bits != 0) {
        count += bits & 1;
        bits >>= 1;
    }
    return count;
}

fn ulong bron_kerbosch_search(usz vertex_count, ulong* adjacency, ulong clique,
                              ulong possible, ulong excluded) {
    if (possible == 0 && excluded == 0) return (ulong)1 << clique;

    long pivot = -1;
    ulong greatest_degree = 0;
    ulong pivot_choices = possible | excluded;
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        if ((pivot_choices & ((ulong)1 << vertex)) == 0) continue;
        ulong degree = population_count(adjacency[vertex]);
        if (pivot < 0 || degree > greatest_degree) {
            pivot = (long)vertex;
            greatest_degree = degree;
        }
    }

    ulong candidates = possible;
    if (pivot >= 0) candidates &= ~adjacency[(usz)pivot];
    ulong result = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        ulong bit = (ulong)1 << vertex;
        if ((candidates & bit) == 0) continue;
        result |= bron_kerbosch_search(vertex_count, adjacency, clique | bit,
                                        possible & adjacency[vertex], excluded & adjacency[vertex]);
        possible &= ~bit;
        excluded |= bit;
    }
    return result;
}

fn long bron_kerbosch(long* input, usz length) @export("bron_kerbosch") {
    if (input == null || length < 1 || length > 7) return -1;
    if (input[0] < 0 || input[0] > 5) return -1;
    usz vertex_count = (usz)input[0];
    if (length != vertex_count + 1) return -1;

    ulong vertex_mask = ((ulong)1 << vertex_count) - 1;
    ulong[5] adjacency;
    for (usz vertex = 0; vertex < vertex_count; vertex++) {
        if (input[vertex + 1] < 0 || ((ulong)input[vertex + 1] & ~vertex_mask) != 0) return -1;
        adjacency[vertex] = (ulong)input[vertex + 1] & ~((ulong)1 << vertex);
    }
    for (usz left = 0; left < vertex_count; left++) {
        for (usz right = left + 1; right < vertex_count; right++) {
            if (((adjacency[left] >> right) & 1) != ((adjacency[right] >> left) & 1)) return -1;
        }
    }
    return (long)bron_kerbosch_search(vertex_count, &adjacency[0], 0, vertex_mask, 0);
}
