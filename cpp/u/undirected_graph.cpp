#include <cstddef>
#include <cstdint>

namespace {
constexpr int MAX_VERTICES = 8;
constexpr int MAX_EDGES = 28;
constexpr int MAX_OPERATIONS = 128;
constexpr std::size_t MAX_INPUT_LENGTH = 599;
constexpr std::int64_t MIN_WEIGHT = -1'000'000;
constexpr std::int64_t MAX_WEIGHT = 1'000'000;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(0xcbf29ce484222325);
constexpr std::uint64_t FNV_PRIME = UINT64_C(0x100000001b3);
constexpr std::uint64_t RESULT_MASK = UINT64_C(0x7fffffffffffffff);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t value) {
    return (hash ^ value) * FNV_PRIME;
}

std::uint64_t hash_i32(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint32_t>(value);
    for (unsigned shift = 0; shift < 32; shift += 8)
        hash = hash_byte(hash, static_cast<std::uint8_t>(bits >> shift));
    return hash;
}

std::uint64_t hash_u32(std::uint64_t hash, std::uint32_t value) {
    for (unsigned shift = 0; shift < 32; shift += 8)
        hash = hash_byte(hash, static_cast<std::uint8_t>(value >> shift));
    return hash;
}

int edge_bit_index(int n, int u, int v) {
    if (u > v) { const int temp = u; u = v; v = temp; }
    int index = 0;
    for (int first = 0; first < u; ++first) index += n - first - 1;
    return index + v - u - 1;
}

int component_count(int n, const std::uint8_t *present) {
    bool seen[MAX_VERTICES] = {};
    int count = 0;
    for (int root = 0; root < n; ++root) {
        if (seen[root]) continue;
        ++count;
        int stack[MAX_VERTICES], size = 0;
        seen[root] = true;
        stack[size++] = root;
        while (size > 0) {
            const int node = stack[--size];
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if (present[node * MAX_VERTICES + neighbor] && !seen[neighbor]) {
                    seen[neighbor] = true;
                    stack[size++] = neighbor;
                }
            }
        }
    }
    return count;
}

void prim_forest(int n, const std::uint8_t *present, const std::int64_t *weights,
                 int &component_total, std::uint32_t &edge_mask) {
    bool in_forest[MAX_VERTICES] = {};
    std::int64_t best_weight[MAX_VERTICES] = {};
    int best_parent[MAX_VERTICES];
    for (int i = 0; i < MAX_VERTICES; ++i) best_parent[i] = -1;
    component_total = 0;
    edge_mask = 0;

    for (int root = 0; root < n; ++root) {
        if (in_forest[root]) continue;
        ++component_total;
        in_forest[root] = true;
        for (int neighbor = 0; neighbor < n; ++neighbor) {
            const int index = root * MAX_VERTICES + neighbor;
            if (present[index] && !in_forest[neighbor]) {
                best_weight[neighbor] = weights[index];
                best_parent[neighbor] = root;
            }
        }
        for (;;) {
            int selected = -1;
            for (int candidate = 0; candidate < n; ++candidate) {
                if (in_forest[candidate] || best_parent[candidate] < 0) continue;
                if (selected < 0 || best_weight[candidate] < best_weight[selected]) selected = candidate;
            }
            if (selected < 0) break;
            const int parent = best_parent[selected];
            edge_mask |= UINT32_C(1) << edge_bit_index(n, parent, selected);
            in_forest[selected] = true;
            best_parent[selected] = -1;
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                const int index = selected * MAX_VERTICES + neighbor;
                if (present[index] && !in_forest[neighbor] &&
                    (best_parent[neighbor] < 0 || weights[index] < best_weight[neighbor])) {
                    best_weight[neighbor] = weights[index];
                    best_parent[neighbor] = selected;
                }
            }
        }
    }
}

int find_root(int *parent, int node) {
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}

void kruskal_forest(int n, const std::uint8_t *present, const std::int64_t *weights,
                    int &component_total, std::uint32_t &edge_mask) {
    int edge_u[MAX_EDGES], edge_v[MAX_EDGES], edge_count = 0;
    std::int64_t edge_weight[MAX_EDGES];
    for (int u = 0; u < n; ++u) {
        for (int v = u + 1; v < n; ++v) {
            const int index = u * MAX_VERTICES + v;
            if (!present[index]) continue;
            edge_u[edge_count] = u;
            edge_v[edge_count] = v;
            edge_weight[edge_count++] = weights[index];
        }
    }
    for (int i = 1; i < edge_count; ++i) {
        const int u = edge_u[i], v = edge_v[i];
        const std::int64_t weight = edge_weight[i];
        int j = i;
        while (j > 0 && edge_weight[j - 1] > weight) {
            edge_u[j] = edge_u[j - 1]; edge_v[j] = edge_v[j - 1]; edge_weight[j] = edge_weight[j - 1];
            --j;
        }
        edge_u[j] = u; edge_v[j] = v; edge_weight[j] = weight;
    }
    int parent[MAX_VERTICES], rank[MAX_VERTICES] = {};
    for (int i = 0; i < n; ++i) parent[i] = i;
    component_total = n;
    edge_mask = 0;
    for (int i = 0; i < edge_count; ++i) {
        const int left = find_root(parent, edge_u[i]);
        const int right = find_root(parent, edge_v[i]);
        if (left == right) continue;
        if (rank[left] < rank[right]) parent[left] = right;
        else if (rank[left] > rank[right]) parent[right] = left;
        else { parent[right] = left; ++rank[left]; }
        --component_total;
        edge_mask |= UINT32_C(1) << edge_bit_index(n, edge_u[i], edge_v[i]);
    }
}
}

extern "C" std::int64_t undirected_graph(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t n_value = input[0], initial_count_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || initial_count_value < 0 || initial_count_value > MAX_EDGES) return -1;
    const int n = static_cast<int>(n_value), initial_count = static_cast<int>(initial_count_value);
    if (initial_count > n * (n - 1) / 2) return -1;
    const std::size_t count_position = 2 + 3 * static_cast<std::size_t>(initial_count);
    if (count_position >= length) return -1;
    const std::int64_t operation_count_value = input[count_position];
    if (operation_count_value < 0 || operation_count_value > MAX_OPERATIONS ||
        length != 3 + 3 * static_cast<std::size_t>(initial_count) + 4 * static_cast<std::size_t>(operation_count_value)) return -1;

    std::uint8_t present[MAX_VERTICES * MAX_VERTICES] = {};
    std::int64_t weights[MAX_VERTICES * MAX_VERTICES] = {};
    for (int edge = 0; edge < initial_count; ++edge) {
        const std::size_t position = 2 + 3 * static_cast<std::size_t>(edge);
        const std::int64_t u_value = input[position], v_value = input[position + 1], weight = input[position + 2];
        if (u_value < 0 || u_value >= v_value || v_value >= n || weight < MIN_WEIGHT || weight > MAX_WEIGHT) return -1;
        const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
        if (present[u * MAX_VERTICES + v]) return -1;
        for (int first = 0; first < n; ++first)
            for (int second = first + 1; second < n; ++second)
                if (present[first * MAX_VERTICES + second] && weights[first * MAX_VERTICES + second] == weight) return -1;
        present[u * MAX_VERTICES + v] = present[v * MAX_VERTICES + u] = 1;
        weights[u * MAX_VERTICES + v] = weights[v * MAX_VERTICES + u] = weight;
    }

    std::uint64_t hash = FNV_OFFSET;
    for (int operation = 0; operation < static_cast<int>(operation_count_value); ++operation) {
        const std::size_t position = count_position + 1 + 4 * static_cast<std::size_t>(operation);
        const std::int64_t opcode = input[position], u_value = input[position + 1];
        const std::int64_t v_value = input[position + 2], weight = input[position + 3];
        std::uint8_t result_code = 0;
        if (opcode == 0) {
            if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value ||
                weight < MIN_WEIGHT || weight > MAX_WEIGHT) return -1;
            const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
            const int index = u * MAX_VERTICES + v, reverse = v * MAX_VERTICES + u;
            const int old_index = u < v ? index : reverse;
            for (int first = 0; first < n; ++first)
                for (int second = first + 1; second < n; ++second) {
                    const int other = first * MAX_VERTICES + second;
                    if (other != old_index && present[other] && weights[other] == weight) return -1;
                }
            present[index] = present[reverse] = 1;
            weights[index] = weights[reverse] = weight;
        } else if (opcode == 1 || opcode == 2) {
            if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value || weight != 0) return -1;
            const int u = static_cast<int>(u_value), v = static_cast<int>(v_value);
            const int index = u * MAX_VERTICES + v, reverse = v * MAX_VERTICES + u;
            if (opcode == 1) { present[index] = present[reverse] = 0; weights[index] = weights[reverse] = 0; }
            else result_code = present[index];
        } else if (opcode == 3) {
            if (u_value != 0 || v_value != 0 || weight != 0) return -1;
            hash = hash_byte(hash, static_cast<std::uint8_t>(opcode));
            hash = hash_byte(hash, result_code);
            hash = hash_byte(hash, static_cast<std::uint8_t>(component_count(n, present)));
            continue;
        } else if (opcode == 4 || opcode == 5 || opcode == 6) {
            if (u_value != 0 || v_value != 0 || weight != 0) return -1;
            int components;
            std::uint32_t mask;
            if (opcode == 5) kruskal_forest(n, present, weights, components, mask);
            else prim_forest(n, present, weights, components, mask);
            hash = hash_byte(hash, static_cast<std::uint8_t>(opcode));
            hash = hash_byte(hash, result_code);
            hash = hash_byte(hash, static_cast<std::uint8_t>(components));
            hash = hash_u32(hash, mask);
            continue;
        } else return -1;
        hash = hash_byte(hash, static_cast<std::uint8_t>(opcode));
        hash = hash_byte(hash, result_code);
    }

    int active_count = 0;
    for (int u = 0; u < n; ++u)
        for (int v = u + 1; v < n; ++v)
            if (present[u * MAX_VERTICES + v]) ++active_count;
    hash = hash_byte(hash, static_cast<std::uint8_t>(n));
    hash = hash_byte(hash, static_cast<std::uint8_t>(active_count));
    for (int u = 0; u < n; ++u)
        for (int v = u + 1; v < n; ++v)
            if (present[u * MAX_VERTICES + v]) {
                hash = hash_byte(hash, static_cast<std::uint8_t>(u));
                hash = hash_byte(hash, static_cast<std::uint8_t>(v));
                hash = hash_i32(hash, weights[u * MAX_VERTICES + v]);
            }
    return static_cast<std::int64_t>(hash & RESULT_MASK);
}
