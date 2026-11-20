module hashiwokakero_small_solver;

const usz MAX_ISLANDS = 6;
const usz MAX_EDGE_SLOTS = 12;
const usz MAX_PARSEABLE_INPUT_LENGTH = 20;

fn bool edges_cross(long* x, long* y, usz* edge_u, usz* edge_v,
                    usz first, usz second) {
    usz a = edge_u[first], b = edge_v[first];
    usz c = edge_u[second], d = edge_v[second];
    bool first_horizontal = y[a] == y[b];
    bool second_horizontal = y[c] == y[d];
    if (first_horizontal == second_horizontal) return false;
    usz h0 = first_horizontal ? a : c;
    usz h1 = first_horizontal ? b : d;
    usz v0 = first_horizontal ? c : a;
    usz v1 = first_horizontal ? d : b;
    long hx = x[v0], hy = y[h0];
    long hmin = x[h0] < x[h1] ? x[h0] : x[h1];
    long hmax = x[h0] > x[h1] ? x[h0] : x[h1];
    long vmin = y[v0] < y[v1] ? y[v0] : y[v1];
    long vmax = y[v0] > y[v1] ? y[v0] : y[v1];
    return hmin < hx && hx < hmax && vmin < hy && hy < vmax;
}

fn bool possible_graph_connected(usz n, usz edge_count, long* x, long* y,
                                 usz* edge_u, usz* edge_v, long* multiplicity,
                                 usz assigned_through) {
    bool[MAX_ISLANDS] reached;
    usz[MAX_ISLANDS] stack;
    for (usz i = 0; i < MAX_ISLANDS; i++) reached[i] = false;
    reached[0] = true;
    usz top = 1;
    stack[0] = 0;
    while (top != 0) {
        top--;
        usz island = stack[top];
        for (usz edge = 0; edge < edge_count; edge++) {
            bool usable = edge <= assigned_through && multiplicity[edge] != 0;
            if (edge > assigned_through) {
                usable = true;
                for (usz fixed = 0; fixed <= assigned_through; fixed++) {
                    if (multiplicity[fixed] != 0 && edges_cross(x, y, edge_u, edge_v, fixed, edge)) {
                        usable = false;
                        break;
                    }
                }
            }
            if (!usable) continue;
            usz neighbor = n;
            if (edge_u[edge] == island) neighbor = edge_v[edge];
            else if (edge_v[edge] == island) neighbor = edge_u[edge];
            if (neighbor < n && !reached[neighbor]) {
                reached[neighbor] = true;
                stack[top] = neighbor;
                top++;
            }
        }
    }
    for (usz island = 0; island < n; island++) if (!reached[island]) return false;
    return true;
}

fn bool residuals_feasible(usz n, long* residual, usz* remaining) {
    for (usz island = 0; island < n; island++)
        if (residual[island] < 0 || residual[island] > (long)(2 * remaining[island])) return false;
    return true;
}

fn bool search(usz n, usz edge_count, long* x, long* y, long* residual,
               usz* remaining, usz* edge_u, usz* edge_v,
               long* multiplicity, long* solution, usz depth) {
    if (depth == edge_count) {
        for (usz island = 0; island < n; island++) if (residual[island] != 0) return false;
        if (!possible_graph_connected(n, edge_count, x, y, edge_u, edge_v,
                                      multiplicity, edge_count - 1)) return false;
        for (usz edge = 0; edge < edge_count; edge++) solution[edge] = multiplicity[edge];
        return true;
    }
    usz u = edge_u[depth], v = edge_v[depth];
    remaining[u]--;
    remaining[v]--;
    for (long amount = 0; amount <= 2; amount++) {
        if (amount > residual[u] || amount > residual[v]) continue;
        bool conflict = false;
        if (amount != 0) {
            for (usz prior = 0; prior < depth; prior++) {
                if (multiplicity[prior] != 0 && edges_cross(x, y, edge_u, edge_v, prior, depth)) {
                    conflict = true;
                    break;
                }
            }
        }
        if (conflict) continue;
        multiplicity[depth] = amount;
        residual[u] -= amount;
        residual[v] -= amount;
        if (residuals_feasible(n, residual, remaining) &&
            possible_graph_connected(n, edge_count, x, y, edge_u, edge_v,
                                     multiplicity, depth) &&
            search(n, edge_count, x, y, residual, remaining, edge_u, edge_v,
                   multiplicity, solution, depth + 1)) {
            residual[u] += amount;
            residual[v] += amount;
            remaining[u]++;
            remaining[v]++;
            return true;
        }
        residual[u] += amount;
        residual[v] += amount;
        multiplicity[depth] = 0;
    }
    remaining[u]++;
    remaining[v]++;
    return false;
}

fn long hashiwokakero_small_solver(long* input, usz length)
    @export("hashiwokakero_small_solver") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_ISLANDS) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 3 * n) return -1;
    long[MAX_ISLANDS] x;
    long[MAX_ISLANDS] y;
    long[MAX_ISLANDS] residual;
    usz[MAX_ISLANDS] remaining;
    usz[MAX_EDGE_SLOTS] edge_u;
    usz[MAX_EDGE_SLOTS] edge_v;
    long[MAX_EDGE_SLOTS] multiplicity;
    long[MAX_EDGE_SLOTS] solution;
    for (usz island = 0; island < MAX_ISLANDS; island++) {
        x[island] = 0; y[island] = 0; residual[island] = 0; remaining[island] = 0;
    }
    for (usz edge = 0; edge < MAX_EDGE_SLOTS; edge++) {
        edge_u[edge] = 0; edge_v[edge] = 0; multiplicity[edge] = 0; solution[edge] = 0;
    }
    for (usz island = 0; island < n; island++) {
        long px = input[1 + 3 * island], py = input[2 + 3 * island];
        long demand = input[3 + 3 * island];
        if (px < 0 || px > 7 || py < 0 || py > 7 || demand < 1 || demand > 8) return -1;
        for (usz prior = 0; prior < island; prior++)
            if (x[prior] == px && y[prior] == py) return -1;
        x[island] = px; y[island] = py; residual[island] = demand;
    }
    usz edge_count = 0;
    for (usz first = 0; first < n; first++) {
        for (usz second = first + 1; second < n; second++) {
            if (x[first] != x[second] && y[first] != y[second]) continue;
            bool blocked = false;
            for (usz middle = 0; middle < n; middle++) {
                if (middle == first || middle == second) continue;
                if (y[first] == y[second] && y[middle] == y[first] &&
                    ((x[first] < x[middle] && x[middle] < x[second]) ||
                     (x[second] < x[middle] && x[middle] < x[first]))) blocked = true;
                if (x[first] == x[second] && x[middle] == x[first] &&
                    ((y[first] < y[middle] && y[middle] < y[second]) ||
                     (y[second] < y[middle] && y[middle] < y[first]))) blocked = true;
            }
            if (!blocked) {
                if (edge_count == MAX_EDGE_SLOTS) return -1;
                edge_u[edge_count] = first; edge_v[edge_count] = second;
                remaining[first]++; remaining[second]++; edge_count++;
            }
        }
    }
    if (!search(n, edge_count, &x[0], &y[0], &residual[0], &remaining[0],
                &edge_u[0], &edge_v[0], &multiplicity[0], &solution[0], 0)) return -2;
    ulong result = 1ul << 32;
    for (usz edge = 0; edge < edge_count; edge++) result |= (ulong)solution[edge] << (2 * edge);
    return (long)result;
}
