module prim;

const usz MAX_VERTICES = 64;
const usz MAX_EDGES = 4096;

// Return the minimum spanning tree weight for a packed undirected edge list.
fn long prim(long* values, usz length) @export("prim")
{
    if (values == null || length < 2 || length > 12290) return -2;
    if (values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096) return -2;
    usz vertices = (usz)values[0];
    usz edges = (usz)values[1];
    if (length != 2 + 3 * edges || (vertices == 0 && edges != 0)) return -2;
    if (vertices == 0) return 0;

    bool[4096] present;
    long[4096] weight;
    for (usz slot = 0; slot < 4096; slot++) present[slot] = false;
    for (usz edge = 0; edge < edges; edge++) {
        long u_value = values[2 + 3 * edge];
        long v_value = values[3 + 3 * edge];
        long cost = values[4 + 3 * edge];
        if (u_value < 0 || v_value < 0 || (ulong)u_value >= (ulong)vertices ||
            (ulong)v_value >= (ulong)vertices || cost < 0 || cost > 2147483647) return -2;
        usz u = (usz)u_value;
        usz v = (usz)v_value;
        if (u == v) continue;
        usz uv = u * MAX_VERTICES + v;
        usz vu = v * MAX_VERTICES + u;
        if (!present[uv] || cost < weight[uv]) {
            present[uv] = true;
            present[vu] = true;
            weight[uv] = cost;
            weight[vu] = cost;
        }
    }

    bool[64] in_tree;
    bool[64] has_best;
    long[64] best;
    for (usz vertex = 0; vertex < 64; vertex++) {
        in_tree[vertex] = false;
        has_best[vertex] = false;
        best[vertex] = 0;
    }
    has_best[0] = true;
    long total = 0;
    for (usz step = 0; step < vertices; step++) {
        usz selected = vertices;
        for (usz vertex = 0; vertex < vertices; vertex++) {
            if (!in_tree[vertex] && has_best[vertex]) {
                if (selected == vertices || best[vertex] < best[selected]) selected = vertex;
            }
        }
        if (selected == vertices) return -1;
        in_tree[selected] = true;
        total += best[selected];
        for (usz vertex = 0; vertex < vertices; vertex++) {
            usz slot = selected * MAX_VERTICES + vertex;
            if (!in_tree[vertex] && present[slot] && (!has_best[vertex] || weight[slot] < best[vertex])) {
                has_best[vertex] = true;
                best[vertex] = weight[slot];
            }
        }
    }
    return total;
}
