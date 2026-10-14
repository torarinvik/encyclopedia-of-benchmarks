module kruskal;

fn void sift_down(long* keys, usz root, usz end) {
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && keys[child] < keys[child + 1]) child++;
        if (keys[root] >= keys[child]) break;
        long temporary = keys[root]; keys[root] = keys[child]; keys[child] = temporary;
        root = child;
    }
}
fn usz find_root(usz* parent, usz node) {
    while (parent[node] != node) { parent[node] = parent[parent[node]]; node = parent[node]; }
    return node;
}
fn long kruskal(long* values, usz length) @export("kruskal") {
    if (values == null || length < 2 || length > 12290) return -2;
    if (values[0] < 0 || values[0] > 64 || values[1] < 0 || values[1] > 4096) return -2;
    usz vertices = (usz)values[0];
    usz edges = (usz)values[1];
    if (length != 2 + 3 * edges || (vertices == 0 && edges != 0)) return -2;
    if (vertices == 0) return 0;
    long[4096] keys;
    for (usz edge = 0; edge < edges; edge++) {
        long u = values[2 + 3 * edge];
        long v = values[3 + 3 * edge];
        long weight = values[4 + 3 * edge];
        if (u < 0 || v < 0 || (ulong)u >= (ulong)vertices || (ulong)v >= (ulong)vertices || weight < 0 || weight > 2147483647) return -2;
        if (u > v) { long temporary = u; u = v; v = temporary; }
        keys[edge] = weight * 4096 + u * 64 + v;
    }
    for (usz start = edges / 2; start > 0;) { start--; sift_down(&keys[0], start, edges); }
    for (usz end = edges; end > 1;) {
        end--; long temporary = keys[0]; keys[0] = keys[end]; keys[end] = temporary;
        sift_down(&keys[0], 0, end);
    }
    usz[64] parent, rank;
    for (usz vertex = 0; vertex < vertices; vertex++) { parent[vertex] = vertex; rank[vertex] = 0; }
    usz selected = 0;
    long total = 0;
    for (usz edge = 0; edge < edges && selected + 1 < vertices; edge++) {
        long key = keys[edge];
        usz u = (usz)((key % 4096) / 64);
        usz v = (usz)(key % 64);
        usz root_u = find_root(&parent[0], u);
        usz root_v = find_root(&parent[0], v);
        if (root_u != root_v) {
            total += key / 4096; selected++;
            if (rank[root_u] < rank[root_v]) { parent[root_u] = root_v; }
            else if (rank[root_u] > rank[root_v]) { parent[root_v] = root_u; }
            else { parent[root_v] = root_u; rank[root_u]++; }
        }
    }
    return selected + 1 == vertices ? total : -1;
}
