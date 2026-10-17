module kruskal_mst;

const usz MAX_VERTICES = 64;
const usz MAX_EDGES = 2016;
const usz MAX_VALID_INPUT_LENGTH = 6050;
const usz MAX_PARSEABLE_INPUT_LENGTH = 6051;
const ulong FNV_OFFSET = 14695981039346656037ul;
const ulong FNV_PRIME = 1099511628211ul;

struct Edge { int u; int v; int weight; }

fn int find_root(int* parent, int node) {
    int root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        int next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

fn void sift_edges(Edge* edges, usz root_input, usz end) {
    usz root = root_input;
    while (root < end / 2) {
        usz child = root * 2 + 1;
        if (child + 1 < end && edges[child].weight < edges[child + 1].weight) child++;
        if (edges[root].weight >= edges[child].weight) return;
        Edge temporary = edges[root];
        edges[root] = edges[child];
        edges[child] = temporary;
        root = child;
    }
}

fn void sort_edges(Edge* edges, usz count) {
    for (usz start = count / 2; start > 0; start--) sift_edges(edges, start - 1, count);
    for (usz end = count; end > 1; end--) {
        Edge temporary = edges[0];
        edges[0] = edges[end - 1];
        edges[end - 1] = temporary;
        sift_edges(edges, 0, end - 1);
    }
}

fn void hash_byte(ulong* hash, uint value) {
    *hash = (*hash ^ (ulong)(value & 255)) * FNV_PRIME;
}

fn void hash_u16(ulong* hash, int value) {
    for (uint byte = 0; byte < 2; byte++) hash_byte(hash, (uint)value >> (byte * 8));
}

fn void hash_i32(ulong* hash, int value) {
    uint bits = (uint)value;
    for (uint byte = 0; byte < 4; byte++) hash_byte(hash, bits >> (byte * 8));
}

fn void hash_i64(ulong* hash, long value) {
    ulong bits = @bitcast(ulong, value);
    for (uint byte = 0; byte < 8; byte++) hash_byte(hash, (uint)(bits >> (byte * 8)));
}

long kruskal_mst(long* input, usz length) @export("kruskal_mst") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    int vertex_count = (int)input[0], edge_count = (int)input[1];
    if (length != 2 + 3 * (usz)edge_count || length > MAX_VALID_INPUT_LENGTH) return -1;
    int max_for_graph = vertex_count * (vertex_count - 1) / 2;
    if (edge_count > max_for_graph || (vertex_count == 1 ? edge_count != 0 : edge_count < vertex_count - 1)) return -1;

    Edge[MAX_EDGES] edges;
    bool[MAX_VERTICES][MAX_VERTICES] seen_pairs = zeroed;
    for (int index = 0; index < edge_count; index++) {
        usz base = 2 + (usz)index * 3;
        long raw_u = input[base], raw_v = input[base + 1], raw_weight = input[base + 2];
        if (raw_u < 0 || raw_u >= (long)vertex_count || raw_v < 0 || raw_v >= (long)vertex_count ||
            raw_u == raw_v || raw_weight < -1000000 || raw_weight > 1000000) return -1;
        int u = (int)raw_u, v = (int)raw_v;
        if (u > v) { int temporary = u; u = v; v = temporary; }
        if (seen_pairs[u][v]) return -1;
        seen_pairs[u][v] = true;
        edges[index] = Edge{u, v, (int)raw_weight};
    }
    sort_edges(&edges[0], (usz)edge_count);
    for (int index = 1; index < edge_count; index++)
        if (edges[index - 1].weight == edges[index].weight) return -1;

    int[MAX_VERTICES] parent;
    int[MAX_VERTICES] rank = zeroed;
    for (int vertex = 0; vertex < vertex_count; vertex++) parent[vertex] = vertex;
    Edge[MAX_VERTICES - 1] selected;
    int selected_count = 0;
    long total_weight = 0;
    for (int index = 0; index < edge_count && selected_count < vertex_count - 1; index++) {
        int left = find_root(&parent[0], edges[index].u);
        int right = find_root(&parent[0], edges[index].v);
        if (left == right) continue;
        if (rank[left] < rank[right]) parent[left] = right;
        else if (rank[left] > rank[right]) parent[right] = left;
        else { parent[right] = left; rank[left]++; }
        selected[selected_count++] = edges[index];
        total_weight += edges[index].weight;
    }
    if (selected_count != vertex_count - 1) return -1;

    ulong hash = FNV_OFFSET;
    hash_u16(&hash, vertex_count);
    hash_u16(&hash, selected_count);
    for (int index = 0; index < selected_count; index++) {
        hash_u16(&hash, selected[index].u);
        hash_u16(&hash, selected[index].v);
        hash_i32(&hash, selected[index].weight);
    }
    hash_i64(&hash, total_weight);
    return (long)(hash & 0x7FFFFFFFFFFFFFFFUL);
}
