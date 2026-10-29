module st_numbering;

const int MAX_VERTICES = 8;
const int MAX_EDGES = 28;
const int MAX_ARCS = 2 * MAX_EDGES;
const usz MAX_INPUT = 4 + 2 * MAX_EDGES;

fn long st_numbering(long* input, usz input_length, char* output, usz output_capacity) @export("st_numbering") {
    if (input == null || input_length < 4 || input_length > MAX_INPUT) return -1;
    long n_value = input[0], m_value = input[1], s_value = input[2], t_value = input[3];
    if (n_value < 2 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES ||
        s_value < 0 || s_value >= n_value || t_value < 0 || t_value >= n_value ||
        s_value == t_value || input_length != 4 + 2 * (usz)m_value) return -1;
    int n = (int)n_value, m = (int)m_value, s = (int)s_value, t = (int)t_value;

    int[MAX_EDGES] edge_u, edge_v;
    ulong[MAX_VERTICES] adjacent;
    for (int vertex = 0; vertex < n; vertex++) adjacent[vertex] = 0;
    int st_edge = -1;
    for (int edge = 0; edge < m; edge++) {
        long u_value = input[4 + 2 * (usz)edge], v_value = input[5 + 2 * (usz)edge];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value) return -1;
        int u = (int)u_value, v = (int)v_value;
        ulong u_bit = 1UL << (usz)v, v_bit = 1UL << (usz)u;
        if ((adjacent[u] & u_bit) != 0) return -1;
        adjacent[u] |= u_bit;
        adjacent[v] |= v_bit;
        edge_u[edge] = u;
        edge_v[edge] = v;
        if ((u == s && v == t) || (u == t && v == s)) st_edge = edge;
    }
    if (st_edge < 0) return -1;

    int[MAX_VERTICES] head;
    for (int vertex = 0; vertex < n; vertex++) head[vertex] = -1;
    int[MAX_ARCS] arc_to, arc_next;
    int arc_count = 0;
    for (int edge = 0; edge < m; edge++) {
        if (edge == st_edge) continue;
        int u = edge_u[edge], v = edge_v[edge];
        arc_to[arc_count] = v; arc_next[arc_count] = head[u]; head[u] = arc_count; arc_count++;
        arc_to[arc_count] = u; arc_next[arc_count] = head[v]; head[v] = arc_count; arc_count++;
    }
    arc_to[arc_count] = t; arc_next[arc_count] = head[s]; head[s] = arc_count; arc_count++;
    arc_to[arc_count] = s; arc_next[arc_count] = head[t]; head[t] = arc_count; arc_count++;

    int[MAX_VERTICES] parent, discovery, low_vertex, children, next_arc, preorder;
    for (int vertex = 0; vertex < n; vertex++) {
        parent[vertex] = -1; discovery[vertex] = 0; low_vertex[vertex] = vertex;
        children[vertex] = 0; next_arc[vertex] = -1;
    }
    int[MAX_VERTICES] stack;
    int top = 0, clock = 1, preorder_count = 1;
    discovery[s] = clock; preorder[0] = s; next_arc[s] = head[s]; stack[top] = s; top++;
    while (top > 0) {
        int vertex = stack[top - 1];
        int arc = next_arc[vertex];
        if (arc < 0) {
            top--;
            int ancestor = parent[vertex];
            if (ancestor >= 0 && discovery[low_vertex[vertex]] < discovery[low_vertex[ancestor]])
                low_vertex[ancestor] = low_vertex[vertex];
            continue;
        }
        next_arc[vertex] = arc_next[arc];
        int neighbor = arc_to[arc];
        if (neighbor == parent[vertex]) continue;
        if (discovery[neighbor] == 0) {
            parent[neighbor] = vertex;
            children[vertex]++;
            clock++;
            discovery[neighbor] = clock;
            low_vertex[neighbor] = neighbor;
            preorder[preorder_count] = neighbor;
            preorder_count++;
            next_arc[neighbor] = head[neighbor];
            stack[top] = neighbor;
            top++;
        } else if (discovery[neighbor] < discovery[vertex] &&
                   discovery[neighbor] < discovery[low_vertex[vertex]]) {
            low_vertex[vertex] = neighbor;
        }
    }
    if (preorder_count != n || children[s] != 1) return -1;
    for (int vertex = 0; vertex < n; vertex++) {
        if (vertex == s) continue;
        for (int child = 0; child < n; child++) {
            if (parent[child] == vertex && discovery[low_vertex[child]] >= discovery[vertex]) return -1;
        }
    }

    int[MAX_VERTICES] previous, following, sign;
    for (int vertex = 0; vertex < n; vertex++) {
        previous[vertex] = -1; following[vertex] = -1; sign[vertex] = 0;
    }
    sign[s] = -1; following[s] = t; previous[t] = s;
    int list_head = s;
    for (int order = 2; order < n; order++) {
        int vertex = preorder[order], ancestor = parent[vertex];
        if (sign[low_vertex[vertex]] == -1) {
            int left = previous[ancestor];
            previous[vertex] = left; following[vertex] = ancestor; previous[ancestor] = vertex;
            if (left >= 0) following[left] = vertex;
            else list_head = vertex;
            sign[ancestor] = 1;
        } else {
            int right = following[ancestor];
            previous[vertex] = ancestor; following[vertex] = right; following[ancestor] = vertex;
            if (right >= 0) previous[right] = vertex;
            sign[ancestor] = -1;
        }
    }

    int[MAX_VERTICES] rank;
    char[MAX_VERTICES] staged;
    for (int vertex = 0; vertex < n; vertex++) { rank[vertex] = 0; staged[vertex] = 0; }
    int rank_value = 1, vertex = list_head;
    while (vertex >= 0 && rank_value <= n) {
        rank[vertex] = rank_value;
        staged[vertex] = (char)rank_value;
        rank_value++;
        vertex = following[vertex];
    }
    if (rank_value != n + 1 || rank[s] != 1 || rank[t] != n) return -1;
    for (int v = 0; v < n; v++) {
        if (v == s || v == t) continue;
        bool lower = false, higher = false;
        for (int arc = head[v]; arc >= 0; arc = arc_next[arc]) {
            int neighbor = arc_to[arc];
            lower = lower || rank[neighbor] < rank[v];
            higher = higher || rank[neighbor] > rank[v];
        }
        if (!lower || !higher) return -1;
    }
    if (output == null || output_capacity < (usz)n) return -2;
    for (int v = 0; v < n; v++) output[v] = staged[v];
    return (long)n;
}
