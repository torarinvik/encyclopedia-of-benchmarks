module manhattan_mst_candidate_edge_reduction;

struct Point { int x; int y; int id; }
struct Edge { int u; int v; int weight; }

const int MAX_N = 31;
const int MAX_CANDIDATES = 4 * MAX_N;

fn bool point_less(Point left, Point right, bool by_sum) {
    if (!by_sum) {
        if (left.x != right.x) return left.x < right.x;
        if (left.y != right.y) return left.y < right.y;
        return left.id < right.id;
    }
    int left_sum = left.x + left.y, right_sum = right.x + right.y;
    if (left_sum != right_sum) return left_sum < right_sum;
    if (left.x != right.x) return left.x < right.x;
    if (left.y != right.y) return left.y < right.y;
    return left.id < right.id;
}

fn void sift_points(Point* points, int root, int end, bool by_sum) {
    while (2 * root + 1 < end) {
        int child = 2 * root + 1;
        if (child + 1 < end && point_less(points[child], points[child + 1], by_sum)) child = child + 1;
        if (!point_less(points[root], points[child], by_sum)) break;
        Point temporary = points[root];
        points[root] = points[child];
        points[child] = temporary;
        root = child;
    }
}

fn void sort_points(Point* points, int n, bool by_sum) {
    int start = n / 2;
    while (start > 0) {
        start = start - 1;
        sift_points(points, start, n, by_sum);
    }
    int end = n;
    while (end > 1) {
        Point temporary = points[0];
        points[0] = points[end - 1];
        points[end - 1] = temporary;
        end = end - 1;
        sift_points(points, 0, end, by_sum);
    }
}

fn void fenwick_add(int* tree, int n, int index, int delta) {
    int at = index + 1;
    while (at <= n) {
        tree[at] = tree[at] + delta;
        at = at + (at & -at);
    }
}

fn int fenwick_prefix(int* tree, int count) {
    int result = 0;
    int at = count;
    while (at > 0) {
        result = result + tree[at];
        at = at - (at & -at);
    }
    return result;
}

fn int fenwick_kth(int* tree, int n, int rank) {
    int index = 0, accumulated = 0, step = 1;
    while (step * 2 <= n) step = step * 2;
    while (step > 0) {
        int next = index + step;
        if (next <= n && accumulated + tree[next] < rank) {
            index = next;
            accumulated = accumulated + tree[next];
        }
        step = step / 2;
    }
    return index;
}

fn void append_edge(Edge* edges, int* edge_count, Point* original, int u, int v) {
    int dx = original[u].x >= original[v].x ? original[u].x - original[v].x : original[v].x - original[u].x;
    int dy = original[u].y >= original[v].y ? original[u].y - original[v].y : original[v].y - original[u].y;
    edges[*edge_count].u = u;
    edges[*edge_count].v = v;
    edges[*edge_count].weight = dx + dy;
    *edge_count = *edge_count + 1;
}

fn bool edge_less(Edge left, Edge right) {
    if (left.weight != right.weight) return left.weight < right.weight;
    int left_u = left.u < left.v ? left.u : left.v;
    int left_v = left.u < left.v ? left.v : left.u;
    int right_u = right.u < right.v ? right.u : right.v;
    int right_v = right.u < right.v ? right.v : right.u;
    if (left_u != right_u) return left_u < right_u;
    return left_v < right_v;
}

fn void sift_edges(Edge* edges, int root, int end) {
    while (2 * root + 1 < end) {
        int child = 2 * root + 1;
        if (child + 1 < end && edge_less(edges[child], edges[child + 1])) child = child + 1;
        if (!edge_less(edges[root], edges[child])) break;
        Edge temporary = edges[root];
        edges[root] = edges[child];
        edges[child] = temporary;
        root = child;
    }
}

fn void sort_edges(Edge* edges, int n) {
    int start = n / 2;
    while (start > 0) {
        start = start - 1;
        sift_edges(edges, start, n);
    }
    int end = n;
    while (end > 1) {
        Edge temporary = edges[0];
        edges[0] = edges[end - 1];
        edges[end - 1] = temporary;
        end = end - 1;
        sift_edges(edges, 0, end);
    }
}

fn int find_root(int* parent, int value) {
    int root = value;
    while (parent[root] != root) root = parent[root];
    while (parent[value] != value) {
        int next = parent[value];
        parent[value] = root;
        value = next;
    }
    return root;
}

fn long manhattan_mst_candidate_edge_reduction(long* input, usz length) @export("manhattan_mst_candidate_edge_reduction") {
    if (input == null || length < 1 || length > (usz)(1 + 2 * MAX_N)) return -1;
    if (input[0] < 0 || input[0] > MAX_N || length != (usz)(1 + 2 * input[0])) return -1;
    int n = (int)input[0];
    Point[MAX_N] points, original;
    ulong[32] seen_x = zeroed, seen_y = zeroed;
    for (int i = 0; i < n; i++) {
        long x = input[1 + 2 * (usz)i], y = input[2 + 2 * (usz)i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        int x_index = (int)x + 1000, y_index = (int)y + 1000;
        int x_word = x_index >> 6, y_word = y_index >> 6;
        ulong x_mask = (ulong)1 << (x_index & 63), y_mask = (ulong)1 << (y_index & 63);
        if ((seen_x[x_word] & x_mask) != 0 || (seen_y[y_word] & y_mask) != 0) return -1;
        seen_x[x_word] = seen_x[x_word] | x_mask;
        seen_y[y_word] = seen_y[y_word] | y_mask;
        points[i].x = (int)x;
        points[i].y = (int)y;
        points[i].id = i;
        original[i] = points[i];
    }
    if (n < 2) return 0;

    Edge[MAX_CANDIDATES] candidates;
    int candidate_count = 0;
    for (int direction = 0; direction < 4; direction++) {
        Point[MAX_N] by_sum, by_x;
        int[MAX_N] rank_by_id;
        for (int i = 0; i < n; i++) { by_sum[i] = points[i]; by_x[i] = points[i]; }
        sort_points(&by_sum[0], n, true);
        sort_points(&by_x[0], n, false);
        for (int rank = 0; rank < n; rank++) rank_by_id[by_x[rank].id] = rank;

        int[MAX_N + 1] active = zeroed;
        for (int i = 0; i < n; i++) {
            Point current = by_sum[i];
            int current_rank = rank_by_id[current.id];
            int active_before = fenwick_prefix(&active[0], current_rank + 1);
            while (active_before > 0) {
                int candidate_rank = fenwick_kth(&active[0], n, active_before);
                int candidate_id = by_x[candidate_rank].id;
                Point candidate = points[candidate_id];
                if (current.x - current.y > candidate.x - candidate.y) break;
                append_edge(&candidates[0], &candidate_count, &original[0], current.id, candidate_id);
                fenwick_add(&active[0], n, candidate_rank, -1);
                active_before = fenwick_prefix(&active[0], current_rank + 1);
            }
            fenwick_add(&active[0], n, current_rank, 1);
        }
        for (int i = 0; i < n; i++) {
            if ((direction & 1) == 0) {
                int old_x = points[i].x;
                points[i].x = points[i].y;
                points[i].y = old_x;
            } else points[i].x = -points[i].x;
        }
    }

    sort_edges(&candidates[0], candidate_count);

    int[MAX_N] parent, component_size;
    for (int i = 0; i < n; i++) { parent[i] = i; component_size[i] = 1; }
    long total = 0;
    int accepted = 0;
    for (int i = 0; i < candidate_count && accepted < n - 1; i++) {
        Edge edge = candidates[i];
        int root_u = find_root(&parent[0], edge.u), root_v = find_root(&parent[0], edge.v);
        if (root_u == root_v) continue;
        if (component_size[root_u] < component_size[root_v]) {
            parent[root_u] = root_v;
            component_size[root_v] = component_size[root_v] + component_size[root_u];
        } else {
            parent[root_v] = root_u;
            component_size[root_u] = component_size[root_u] + component_size[root_v];
        }
        total = total + edge.weight;
        accepted = accepted + 1;
    }
    return accepted == n - 1 ? total : -1;
}
