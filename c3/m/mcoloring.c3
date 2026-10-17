module mcoloring;

const int MAX_VERTICES = 14;
const usz MAX_PARSEABLE_INPUT_LENGTH = 17;

fn int find_root(int* parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

long mcoloring(long* input, usz length) @export("mcoloring") {
    if (input == null || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long n_value = input[0], colors_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || colors_value < 1 || colors_value > MAX_VERTICES) return -1;
    int n = (int)n_value;
    if (length != (usz)n + 2) return -1;

    uint masks[MAX_VERTICES] = {0};
    uint valid_mask = n == 0 ? 0u : (1u << n) - 1u;
    int parent[MAX_VERTICES];
    for (int vertex = 0; vertex < n; vertex++) {
        long raw = input[vertex + 2];
        if (raw < 0 || (ulong)raw > (ulong)valid_mask) return -1;
        masks[vertex] = (uint)raw;
        if ((masks[vertex] & (1u << vertex)) != 0) return -1;
        parent[vertex] = vertex;
    }
    for (int vertex = 0; vertex < n; vertex++) {
        for (int neighbor = vertex + 1; neighbor < n; neighbor++) {
            bool edge = (masks[vertex] & (1u << neighbor)) != 0;
            if (edge != ((masks[neighbor] & (1u << vertex)) != 0)) return -1;
            if (edge) {
                int root_a = find_root(&parent[0], vertex), root_b = find_root(&parent[0], neighbor);
                if (root_a == root_b) return -1;
                parent[root_a] = root_b;
            }
        }
    }

    int colors[MAX_VERTICES], queue[MAX_VERTICES];
    bool visited[MAX_VERTICES] = {false};
    for (int i = 0; i < n; i++) colors[i] = 1;
    int maximum_color = 1;
    for (int start = 0; start < n; start++) {
        if (visited[start]) continue;
        int head = 0, tail = 0;
        visited[start] = true;
        queue[tail++] = start;
        while (head < tail) {
            int vertex = queue[head++];
            for (int neighbor = 0; neighbor < n; neighbor++) {
                if ((masks[vertex] & (1u << neighbor)) == 0) continue;
                if (colors[vertex] == colors[neighbor]) colors[neighbor]++;
                if (colors[vertex] > maximum_color) maximum_color = colors[vertex];
                if (colors[neighbor] > maximum_color) maximum_color = colors[neighbor];
                if (maximum_color > colors_value) return 0;
                if (!visited[neighbor]) {
                    visited[neighbor] = true;
                    queue[tail++] = neighbor;
                }
            }
        }
    }
    return 1;
}
