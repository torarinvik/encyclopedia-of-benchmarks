module undirected_graph;

const int MAX_VERTICES = 8;
const int MAX_EDGES = 28;
const int MAX_OPERATIONS = 128;
const usz MAX_INPUT_LENGTH = 599;
const long MIN_WEIGHT = -1000000;
const long MAX_WEIGHT = 1000000;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;
const ulong RESULT_MASK = 0x7fffffffffffffff;

fn ulong hash_byte(ulong hash, uint8 value) { return (hash ^ (ulong)value) * FNV_PRIME; }

fn ulong hash_i32(ulong hash, long value) {
    uint bits = (uint)value;
    for (uint shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, (uint8)(bits >> shift));
    return hash;
}

fn ulong hash_u32(ulong hash, uint value) {
    for (uint shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, (uint8)(value >> shift));
    return hash;
}

fn int edge_bit_index(int n, int u, int v) {
    if (u > v) { int temp = u; u = v; v = temp; }
    int index = 0;
    for (int first = 0; first < u; first++) index += n - first - 1;
    return index + v - u - 1;
}

fn int component_count(int n, uint8* present) {
    uint8[8] seen = zeroed;
    int count = 0;
    for (int root = 0; root < n; root++) {
        if (seen[root]) continue;
        count++;
        int[8] stack;
        int size = 0;
        seen[root] = 1;
        stack[size++] = root;
        while (size > 0) {
            int node = stack[--size];
            for (int neighbor = 0; neighbor < n; neighbor++) {
                if (present[node * MAX_VERTICES + neighbor] && !seen[neighbor]) {
                    seen[neighbor] = 1;
                    stack[size++] = neighbor;
                }
            }
        }
    }
    return count;
}

fn void prim_forest(int n, uint8* present, long* weights, int* component_total, uint* edge_mask) {
    uint8[8] in_forest = zeroed;
    long[8] best_weight = zeroed;
    int[8] best_parent;
    for (int i = 0; i < MAX_VERTICES; i++) best_parent[i] = -1;
    *component_total = 0;
    *edge_mask = 0;
    for (int root = 0; root < n; root++) {
        if (in_forest[root]) continue;
        *component_total += 1;
        in_forest[root] = 1;
        for (int neighbor = 0; neighbor < n; neighbor++) {
            int index = root * MAX_VERTICES + neighbor;
            if (present[index] && !in_forest[neighbor]) {
                best_weight[neighbor] = weights[index];
                best_parent[neighbor] = root;
            }
        }
        while (true) {
            int selected = -1;
            for (int candidate = 0; candidate < n; candidate++) {
                if (in_forest[candidate] || best_parent[candidate] < 0) continue;
                if (selected < 0 || best_weight[candidate] < best_weight[selected]) selected = candidate;
            }
            if (selected < 0) break;
            int parent = best_parent[selected];
            *edge_mask |= ((uint)1) << edge_bit_index(n, parent, selected);
            in_forest[selected] = 1;
            best_parent[selected] = -1;
            for (int neighbor = 0; neighbor < n; neighbor++) {
                int index = selected * MAX_VERTICES + neighbor;
                if (present[index] && !in_forest[neighbor] &&
                    (best_parent[neighbor] < 0 || weights[index] < best_weight[neighbor])) {
                    best_weight[neighbor] = weights[index];
                    best_parent[neighbor] = selected;
                }
            }
        }
    }
}

fn int find_root(int* parent, int node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

fn void kruskal_forest(int n, uint8* present, long* weights, int* component_total, uint* edge_mask) {
    int[28] edge_u;
    int[28] edge_v;
    long[28] edge_weight;
    int edge_count = 0;
    for (int u = 0; u < n; u++) for (int v = u + 1; v < n; v++) {
        int index = u * MAX_VERTICES + v;
        if (present[index]) {
            edge_u[edge_count] = u;
            edge_v[edge_count] = v;
            edge_weight[edge_count++] = weights[index];
        }
    }
    for (int i = 1; i < edge_count; i++) {
        int u = edge_u[i], v = edge_v[i];
        long weight = edge_weight[i];
        int j = i;
        while (j > 0 && edge_weight[j - 1] > weight) {
            edge_u[j] = edge_u[j - 1]; edge_v[j] = edge_v[j - 1]; edge_weight[j] = edge_weight[j - 1];
            j--;
        }
        edge_u[j] = u; edge_v[j] = v; edge_weight[j] = weight;
    }
    int[8] parent;
    int[8] rank = zeroed;
    for (int i = 0; i < n; i++) parent[i] = i;
    *component_total = n;
    *edge_mask = 0;
    for (int i = 0; i < edge_count; i++) {
        int left = find_root(&parent[0], edge_u[i]);
        int right = find_root(&parent[0], edge_v[i]);
        if (left == right) continue;
        if (rank[left] < rank[right]) parent[left] = right;
        else if (rank[left] > rank[right]) parent[right] = left;
        else { parent[right] = left; rank[left]++; }
        *component_total -= 1;
        *edge_mask |= ((uint)1) << edge_bit_index(n, edge_u[i], edge_v[i]);
    }
}

fn long undirected_graph(long* input, usz length) @export("undirected_graph") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], initial_count_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || initial_count_value < 0 || initial_count_value > MAX_EDGES) return -1;
    int n = (int)n_value, initial_count = (int)initial_count_value;
    if (initial_count > n * (n - 1) / 2) return -1;
    usz count_position = 2 + 3 * (usz)initial_count;
    if (count_position >= length) return -1;
    long operation_count_value = input[count_position];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS ||
        length != 3 + 3 * (usz)initial_count + 4 * (usz)operation_count_value) return -1;

    uint8[64] present = zeroed;
    long[64] weights = zeroed;
    for (int edge = 0; edge < initial_count; edge++) {
        usz position = 2 + 3 * (usz)edge;
        long u_value = input[position], v_value = input[position + 1], weight = input[position + 2];
        if (u_value < 0 || u_value >= v_value || v_value >= n || weight < MIN_WEIGHT || weight > MAX_WEIGHT) return -1;
        int u = (int)u_value, v = (int)v_value;
        if (present[u * MAX_VERTICES + v]) return -1;
        for (int first = 0; first < n; first++) for (int second = first + 1; second < n; second++)
            if (present[first * MAX_VERTICES + second] && weights[first * MAX_VERTICES + second] == weight) return -1;
        present[u * MAX_VERTICES + v] = 1; present[v * MAX_VERTICES + u] = 1;
        weights[u * MAX_VERTICES + v] = weight; weights[v * MAX_VERTICES + u] = weight;
    }

    ulong hash = FNV_OFFSET;
    for (int operation = 0; operation < (int)operation_count_value; operation++) {
        usz position = count_position + 1 + 4 * (usz)operation;
        long opcode = input[position], u_value = input[position + 1], v_value = input[position + 2], weight = input[position + 3];
        uint8 result_code = 0;
        if (opcode == 0) {
            if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value || weight < MIN_WEIGHT || weight > MAX_WEIGHT) return -1;
            int u = (int)u_value, v = (int)v_value;
            int index = u * MAX_VERTICES + v, reverse = v * MAX_VERTICES + u;
            int old_index = u < v ? index : reverse;
            for (int first = 0; first < n; first++) for (int second = first + 1; second < n; second++) {
                int other = first * MAX_VERTICES + second;
                if (other != old_index && present[other] && weights[other] == weight) return -1;
            }
            present[index] = 1; present[reverse] = 1; weights[index] = weight; weights[reverse] = weight;
        } else if (opcode == 1 || opcode == 2) {
            if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value || weight != 0) return -1;
            int u = (int)u_value, v = (int)v_value;
            int index = u * MAX_VERTICES + v, reverse = v * MAX_VERTICES + u;
            if (opcode == 1) { present[index] = 0; present[reverse] = 0; weights[index] = 0; weights[reverse] = 0; }
            else result_code = present[index];
        } else if (opcode == 3) {
            if (u_value != 0 || v_value != 0 || weight != 0) return -1;
            hash = hash_byte(hash, (uint8)opcode); hash = hash_byte(hash, result_code);
            hash = hash_byte(hash, (uint8)component_count(n, &present[0]));
            continue;
        } else if (opcode == 4 || opcode == 5 || opcode == 6) {
            if (u_value != 0 || v_value != 0 || weight != 0) return -1;
            int components; uint mask;
            if (opcode == 5) kruskal_forest(n, &present[0], &weights[0], &components, &mask);
            else prim_forest(n, &present[0], &weights[0], &components, &mask);
            hash = hash_byte(hash, (uint8)opcode); hash = hash_byte(hash, result_code);
            hash = hash_byte(hash, (uint8)components); hash = hash_u32(hash, mask);
            continue;
        } else return -1;
        hash = hash_byte(hash, (uint8)opcode); hash = hash_byte(hash, result_code);
    }

    int active_count = 0;
    for (int u = 0; u < n; u++) for (int v = u + 1; v < n; v++) if (present[u * MAX_VERTICES + v]) active_count++;
    hash = hash_byte(hash, (uint8)n); hash = hash_byte(hash, (uint8)active_count);
    for (int u = 0; u < n; u++) for (int v = u + 1; v < n; v++) if (present[u * MAX_VERTICES + v]) {
        hash = hash_byte(hash, (uint8)u); hash = hash_byte(hash, (uint8)v);
        hash = hash_i32(hash, weights[u * MAX_VERTICES + v]);
    }
    return (long)(hash & RESULT_MASK);
}
