module depth_first_search_recursive;

const int MAX_VERTICES = 64;
const int MAX_EDGES = 256;

fn bool reachable(long* adjacency, int* degree, int current, long target, bool* visited) {
    if ((long)current == target) return true;
    visited[current] = true;
    for (int position = 0; position < degree[current]; position++) {
        int neighbor = (int)adjacency[current * MAX_VERTICES + position];
        if (!visited[neighbor] && reachable(adjacency, degree, neighbor, target, visited)) return true;
    }
    return false;
}

fn long depth_first_search_recursive(long* input, usz length) @export("depth_first_search_recursive") {
    if (input == null || length < 4 || length > 518) return -1;
    long vertex_count = input[0], edge_count_value = input[1];
    long source = input[2], target = input[3];
    if (vertex_count < 1 || vertex_count > MAX_VERTICES || edge_count_value < 0
        || edge_count_value > MAX_EDGES || source < 0 || source >= vertex_count) return -1;
    int edge_count = (int)edge_count_value;
    if (length != 4 + 2 * (usz)edge_count) return -1;
    for (int edge = 0; edge < edge_count; edge++) {
        long left = input[4 + 2 * edge], right = input[5 + 2 * edge];
        if (left < 0 || left >= vertex_count || right < 0 || right >= vertex_count) return -1;
    }

    long[MAX_VERTICES * MAX_VERTICES] adjacency;
    int[MAX_VERTICES] degree = zeroed;
    u64[MAX_VERTICES] seen = zeroed;
    for (int edge = 0; edge < edge_count; edge++) {
        int left = (int)input[4 + 2 * edge], right = (int)input[5 + 2 * edge];
        u64 right_bit = (u64)1 << (uint)right;
        if ((seen[left] & right_bit) == 0) {
            seen[left] |= right_bit;
            adjacency[left * MAX_VERTICES + degree[left]] = right;
            degree[left]++;
        }
        u64 left_bit = (u64)1 << (uint)left;
        if ((seen[right] & left_bit) == 0) {
            seen[right] |= left_bit;
            adjacency[right * MAX_VERTICES + degree[right]] = left;
            degree[right]++;
        }
    }
    bool[MAX_VERTICES] visited = zeroed;
    return reachable(&adjacency[0], &degree[0], (int)source, target, &visited[0]) ? 1 : 0;
}
