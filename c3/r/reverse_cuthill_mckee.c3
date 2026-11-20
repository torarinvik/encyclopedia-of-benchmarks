module reverse_cuthill_mckee;

const int MAX_VERTICES = 8;
const int MAX_EDGES = 28;
const usz MAX_INPUT_LENGTH = 59;

fn bool neighbor_precedes(int left, int right, int* degree) {
    return degree[left] != degree[right] ? degree[left] < degree[right] : left < right;
}

fn long reverse_cuthill_mckee(long* input, usz length)
        @export("reverse_cuthill_mckee") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_VERTICES || m64 < 0 || m64 > MAX_EDGES) return -1;
    int n = (int)n64, m = (int)m64;
    if (m > n * (n - 1) / 2 || length != (usz)(2 + 2 * m)) return -1;

    bool[MAX_VERTICES][MAX_VERTICES] adjacent = zeroed;
    int[MAX_VERTICES] degree = zeroed;
    int[MAX_EDGES] edge_u = zeroed, edge_v = zeroed;
    for (int edge = 0; edge < m; edge += 1) {
        long left64 = input[2 + 2 * edge], right64 = input[3 + 2 * edge];
        if (left64 < 0 || right64 < 0 || left64 >= n || right64 >= n || left64 == right64) return -1;
        int left = (int)left64, right = (int)right64;
        if (adjacent[left][right]) return -1;
        adjacent[left][right] = true;
        adjacent[right][left] = true;
        degree[left] += 1;
        degree[right] += 1;
        edge_u[edge] = left;
        edge_v[edge] = right;
    }

    bool[MAX_VERTICES] visited = zeroed;
    int[MAX_VERTICES] order = zeroed;
    int order_count = 0;
    while (order_count < n) {
        int root = -1;
        for (int vertex = 0; vertex < n; vertex += 1) {
            if (!visited[vertex] &&
                (root < 0 || degree[vertex] < degree[root] ||
                 (degree[vertex] == degree[root] && vertex < root))) root = vertex;
        }
        int[MAX_VERTICES] queue = zeroed;
        int head = 0, tail = 0;
        visited[root] = true;
        queue[tail] = root;
        tail += 1;
        order[order_count] = root;
        order_count += 1;
        while (head < tail) {
            int vertex = queue[head];
            head += 1;
            int[MAX_VERTICES] neighbors = zeroed;
            int neighbor_count = 0;
            for (int neighbor = 0; neighbor < n; neighbor += 1)
                if (adjacent[vertex][neighbor] && !visited[neighbor]) {
                    neighbors[neighbor_count] = neighbor;
                    neighbor_count += 1;
                }
            for (int i = 1; i < neighbor_count; i += 1) {
                int key = neighbors[i], j = i;
                while (j > 0 && neighbor_precedes(key, neighbors[j - 1], &degree[0])) {
                    neighbors[j] = neighbors[j - 1];
                    j -= 1;
                }
                neighbors[j] = key;
            }
            for (int i = 0; i < neighbor_count; i += 1) {
                int neighbor = neighbors[i];
                if (visited[neighbor]) continue;
                visited[neighbor] = true;
                queue[tail] = neighbor;
                tail += 1;
                order[order_count] = neighbor;
                order_count += 1;
            }
        }
    }

    for (int left = 0, right = n - 1; left < right; left += 1, right -= 1) {
        int temporary = order[left];
        order[left] = order[right];
        order[right] = temporary;
    }
    int[MAX_VERTICES] position = zeroed;
    long rank_word = 0;
    for (int rank = 0; rank < n; rank += 1) {
        position[order[rank]] = rank;
        rank_word |= ((long)order[rank]) << (3 * rank);
    }
    int bandwidth = 0;
    for (int edge = 0; edge < m; edge += 1) {
        int difference = position[edge_u[edge]] - position[edge_v[edge]];
        if (difference < 0) difference = -difference;
        if (difference > bandwidth) bandwidth = difference;
    }
    return ((long)bandwidth << 24) | rank_word;
}
