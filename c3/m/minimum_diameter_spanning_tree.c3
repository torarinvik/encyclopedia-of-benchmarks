module minimum_diameter_spanning_tree;

const usz MAX_N = 8;
const usz MAX_M = 20;
const usz MAX_INPUT_VALUES = 2 + 3 * MAX_M + 1;
const long INF = 1000000000000;

fn void shortest_tree(usz n, usz m, usz[MAX_M]* edge_u, usz[MAX_M]* edge_v,
    long[MAX_M]* edge_weight, int center_kind, usz center_root, long center_x2,
    usz center_edge, long[MAX_N]* distance, long[MAX_N]* parent_edge) {
    bool[MAX_N] settled = zeroed;
    for (usz vertex = 0; vertex < n; vertex += 1) {
        distance[vertex] = INF;
        parent_edge[vertex] = -1;
    }
    if (center_kind == 0) {
        distance[center_root] = 0;
    } else {
        usz u = edge_u[center_edge], v = edge_v[center_edge];
        if (u > v) { usz temporary = u; u = v; v = temporary; }
        distance[u] = center_x2;
        distance[v] = 2 * edge_weight[center_edge] - center_x2;
    }
    for (usz step = 0; step < n; step += 1) {
        usz current = n;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            if (!settled[vertex] && (current == n || distance[vertex] < distance[current]))
                current = vertex;
        }
        if (current == n || distance[current] == INF) return;
        settled[current] = true;
        for (usz edge_id = 0; edge_id < m; edge_id += 1) {
            usz left = edge_u[edge_id], right = edge_v[edge_id];
            if (left == right) continue;
            usz neighbor;
            if (current == left) neighbor = right;
            else if (current == right) neighbor = left;
            else continue;
            long candidate = distance[current] + 2 * edge_weight[edge_id];
            if (!settled[neighbor] && candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent_edge[neighbor] = (long)edge_id;
            }
        }
    }
}

fn long selected_tree_diameter(usz n, usz[MAX_N]* selected, usz[MAX_M]* edge_u,
    usz[MAX_M]* edge_v, long[MAX_M]* edge_weight) {
    bool[MAX_N * MAX_N] adjacent = zeroed;
    long[MAX_N * MAX_N] weight = zeroed;
    for (usz index = 0; index + 1 < n; index += 1) {
        usz edge_id = selected[index];
        usz u = edge_u[edge_id], v = edge_v[edge_id];
        adjacent[u * MAX_N + v] = true;
        adjacent[v * MAX_N + u] = true;
        weight[u * MAX_N + v] = edge_weight[edge_id];
        weight[v * MAX_N + u] = edge_weight[edge_id];
    }
    long diameter = 0;
    for (usz source = 0; source < n; source += 1) {
        long[MAX_N] distance;
        usz[MAX_N] parent, stack;
        for (usz vertex = 0; vertex < n; vertex += 1) {
            distance[vertex] = -1;
            parent[vertex] = n;
        }
        usz top = 1;
        stack[0] = source;
        distance[source] = 0;
        while (top > 0) {
            top -= 1;
            usz current = stack[top];
            if (distance[current] > diameter) diameter = distance[current];
            for (usz neighbor = 0; neighbor < n; neighbor += 1) {
                usz cell = current * MAX_N + neighbor;
                if (adjacent[cell] && parent[current] != neighbor && distance[neighbor] < 0) {
                    parent[neighbor] = current;
                    distance[neighbor] = distance[current] + weight[cell];
                    stack[top] = neighbor;
                    top += 1;
                }
            }
        }
    }
    return diameter;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long minimum_diameter_spanning_tree(long* input, usz length, char* output, usz capacity)
    @export("minimum_diameter_spanning_tree") {
    if (input == null || length < 2 || length > MAX_INPUT_VALUES) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || m_value < 0 || m_value > (long)MAX_M) return -1;
    usz n = (usz)n_value, m = (usz)m_value;
    if (length != 2 + 3 * m) return -1;

    usz[MAX_M] edge_u, edge_v;
    long[MAX_M] edge_weight;
    long[MAX_N * MAX_N] graph_distance;
    for (usz u = 0; u < n; u += 1) {
        for (usz v = 0; v < n; v += 1)
            graph_distance[u * MAX_N + v] = u == v ? 0 : INF;
    }
    for (usz edge_id = 0; edge_id < m; edge_id += 1) {
        usz offset = 2 + 3 * edge_id;
        long u_value = input[offset], v_value = input[offset + 1], edge_w = input[offset + 2];
        if (u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value ||
            edge_w < 0 || edge_w > 9) return -1;
        usz u = (usz)u_value, v = (usz)v_value;
        edge_u[edge_id] = u;
        edge_v[edge_id] = v;
        edge_weight[edge_id] = edge_w;
        if (u != v && edge_w < graph_distance[u * MAX_N + v]) {
            graph_distance[u * MAX_N + v] = edge_w;
            graph_distance[v * MAX_N + u] = edge_w;
        }
    }
    for (usz middle = 0; middle < n; middle += 1) {
        for (usz left = 0; left < n; left += 1) {
            for (usz right = 0; right < n; right += 1) {
                long candidate = graph_distance[left * MAX_N + middle] +
                    graph_distance[middle * MAX_N + right];
                usz cell = left * MAX_N + right;
                if (candidate < graph_distance[cell]) graph_distance[cell] = candidate;
            }
        }
    }
    for (usz vertex = 0; vertex < n; vertex += 1)
        if (graph_distance[vertex] == INF) return -1;

    long best_radius2 = INF, best_x2 = 0;
    int best_kind = 0;
    usz best_root = 0, best_edge = 0;
    for (usz root = 0; root < n; root += 1) {
        long eccentricity = 0;
        for (usz vertex = 0; vertex < n; vertex += 1)
            if (graph_distance[root * MAX_N + vertex] > eccentricity)
                eccentricity = graph_distance[root * MAX_N + vertex];
        long radius2 = 2 * eccentricity;
        if (radius2 < best_radius2) {
            best_radius2 = radius2;
            best_kind = 0;
            best_root = root;
        }
    }
    for (usz edge_id = 0; edge_id < m; edge_id += 1) {
        usz u = edge_u[edge_id], v = edge_v[edge_id];
        long edge_w = edge_weight[edge_id];
        if (u == v) continue;
        if (u > v) { usz temporary = u; u = v; v = temporary; }
        for (long x2 = 0; x2 <= 2 * edge_w; x2 += 1) {
            long radius2 = 0;
            for (usz vertex = 0; vertex < n; vertex += 1) {
                long from_u = 2 * graph_distance[u * MAX_N + vertex] + x2;
                long from_v = 2 * graph_distance[v * MAX_N + vertex] + 2 * edge_w - x2;
                long value = from_u < from_v ? from_u : from_v;
                if (value > radius2) radius2 = value;
            }
            if (radius2 < best_radius2) {
                best_radius2 = radius2;
                best_kind = 1;
                best_root = u;
                best_x2 = x2;
                best_edge = edge_id;
            }
        }
    }

    long center_distance[MAX_N], parent_edge[MAX_N];
    shortest_tree(n, m, &edge_u[0], &edge_v[0], &edge_weight[0], best_kind, best_root,
        best_x2, best_edge, &center_distance[0], &parent_edge[0]);
    usz[MAX_N] selected;
    usz selected_count = 0;
    for (usz vertex = 0; vertex < n; vertex += 1)
        if (parent_edge[vertex] >= 0) selected[selected_count++] = (usz)parent_edge[vertex];
    if (selected_count + 2 == n && best_kind == 1) {
        usz u = edge_u[best_edge], v = edge_v[best_edge];
        if (parent_edge[u] == -1 && parent_edge[v] == -1) selected[selected_count++] = best_edge;
    }
    if (selected_count != n - 1) return -1;
    for (usz i = 0; i < selected_count; i += 1)
        for (usz j = i + 1; j < selected_count; j += 1)
            if (selected[j] < selected[i]) { usz temporary = selected[i]; selected[i] = selected[j]; selected[j] = temporary; }

    long staged[MAX_N];
    staged[0] = selected_tree_diameter(n, &selected[0], &edge_u[0], &edge_v[0], &edge_weight[0]);
    for (usz index = 0; index < selected_count; index += 1) staged[index + 1] = (long)selected[index];
    usz required = 8 * n;
    if (output == null || capacity < required) return -2;
    for (usz index = 0; index < n; index += 1) store_i64_le(output, 8 * index, staged[index]);
    return (long)required;
}
