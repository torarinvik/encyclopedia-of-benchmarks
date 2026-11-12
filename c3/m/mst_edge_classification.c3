module mst_edge_classification;

const usz MAX_VERTICES = 12;
const usz MAX_EDGES = 24;
const usz MAX_INPUT_LENGTH = 2 + 3 * MAX_EDGES + 1;

fn usz find_root(long* parent, usz vertex) {
    while ((usz)parent[vertex] != vertex) {
        parent[vertex] = parent[(usz)parent[vertex]];
        vertex = (usz)parent[vertex];
    }
    return vertex;
}

fn void join_roots(long* parent, usz left, usz right) {
    usz a = find_root(parent, left);
    usz b = find_root(parent, right);
    if (a != b) parent[b] = (long)a;
}

fn bool alternative_path_exists(usz* left, usz* right, usz* edge_id,
        usz edge_count, usz omitted_edge, usz source, usz target) {
    bool[MAX_VERTICES] seen;
    usz[MAX_VERTICES] queue;
    for (usz i = 0; i < MAX_VERTICES; i++) seen[i] = false;
    usz head = 0, tail = 0;
    seen[source] = true;
    queue[tail++] = source;
    while (head < tail) {
        usz vertex = queue[head++];
        if (vertex == target) return true;
        for (usz edge = 0; edge < edge_count; edge++) {
            if (edge_id[edge] == omitted_edge) continue;
            usz neighbor = MAX_VERTICES;
            if (left[edge] == vertex) neighbor = right[edge];
            else if (right[edge] == vertex) neighbor = left[edge];
            if (neighbor < MAX_VERTICES && !seen[neighbor]) {
                seen[neighbor] = true;
                queue[tail++] = neighbor;
            }
        }
    }
    return false;
}

fn long mst_edge_classification(long* input, usz length, char* output,
        usz output_capacity) @export("mst_edge_classification") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES || input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertex_count = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 2 + 3 * edge_count) return -1;

    usz[MAX_EDGES] left, right, weight, order;
    char[MAX_EDGES] classes;
    for (usz edge = 0; edge < MAX_EDGES; edge++) classes[edge] = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long u = input[2 + 3 * edge];
        long v = input[3 + 3 * edge];
        long w = input[4 + 3 * edge];
        if (u < 0 || u >= v || v >= (long)vertex_count || w < 0 || w > 20) return -1;
        left[edge] = (usz)u; right[edge] = (usz)v; weight[edge] = (usz)w; order[edge] = edge;
        for (usz prior = 0; prior < edge; prior++)
            if (left[prior] == left[edge] && right[prior] == right[edge]) return -1;
    }
    for (usz i = 1; i < edge_count; i++) {
        usz item = order[i];
        usz j = i;
        while (j > 0 && (weight[order[j - 1]] > weight[item] ||
                (weight[order[j - 1]] == weight[item] && order[j - 1] > item))) {
            order[j] = order[j - 1];
            j--;
        }
        order[j] = item;
    }
    long[MAX_VERTICES] parent;
    for (usz vertex = 0; vertex < vertex_count; vertex++) parent[vertex] = (long)vertex;
    usz start = 0;
    while (start < edge_count) {
        usz stop = start + 1;
        usz group_weight = weight[order[start]];
        while (stop < edge_count && weight[order[stop]] == group_weight) stop++;
        usz[MAX_EDGES] q_left, q_right, q_id;
        usz q_count = 0;
        for (usz pos = start; pos < stop; pos++) {
            usz id = order[pos];
            usz a = find_root(&parent[0], left[id]);
            usz b = find_root(&parent[0], right[id]);
            if (a != b) { q_left[q_count] = a; q_right[q_count] = b; q_id[q_count] = id; q_count++; }
        }
        for (usz e = 0; e < q_count; e++)
            classes[q_id[e]] = alternative_path_exists(&q_left[0], &q_right[0], &q_id[0],
                q_count, q_id[e], q_left[e], q_right[e]) ? 1 : 2;
        for (usz pos = start; pos < stop; pos++) {
            usz id = order[pos];
            join_roots(&parent[0], left[id], right[id]);
        }
        start = stop;
    }
    usz representative = find_root(&parent[0], 0);
    for (usz vertex = 1; vertex < vertex_count; vertex++)
        if (find_root(&parent[0], vertex) != representative) return -1;
    if (output_capacity < edge_count || (edge_count > 0 && output == null)) return -2;
    for (usz edge = 0; edge < edge_count; edge++) output[edge] = classes[edge];
    return (long)edge_count;
}
