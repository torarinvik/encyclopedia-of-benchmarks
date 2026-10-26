module bst_interleave_bound;

const usz MAX_NODES = 8;
const usz MAX_ACCESSES = 16;
const usz MAX_INPUT = 36;

fn void store_i64_le(char* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[byte] = (char)(bits & 255); bits >>= 8; }
}

fn long bst_interleave_bound(long* input, usz length, char* output, usz capacity) @export("bst_interleave_bound") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_raw = input[0], root_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_NODES || root_raw < 0 || root_raw >= n_raw) return -1;
    int n = (int)n_raw, root = (int)root_raw;
    int[MAX_NODES] left = {-1,-1,-1,-1,-1,-1,-1,-1};
    int[MAX_NODES] right = {-1,-1,-1,-1,-1,-1,-1,-1};
    int[MAX_NODES] parent = {-1,-1,-1,-1,-1,-1,-1,-1};
    int[MAX_NODES] parent_count = zeroed;
    usz position = 2;
    for (int node = 0; node < n; node += 1) {
        if (position + 2 > length) return -1;
        long l = input[position], r = input[position + 1]; position += 2;
        if (l < -1 || l >= n || r < -1 || r >= n || l == node || r == node || (l >= 0 && l == r)) return -1;
        left[node] = (int)l; right[node] = (int)r;
        if (l >= 0) { parent_count[(int)l] += 1; parent[(int)l] = node; }
        if (r >= 0) { parent_count[(int)r] += 1; parent[(int)r] = node; }
    }
    if (parent_count[root] != 0) return -1;
    for (int node = 0; node < n; node += 1) if (node != root && parent_count[node] != 1) return -1;
    if (position >= length) return -1;
    long m_raw = input[position]; position += 1;
    if (m_raw < 0 || m_raw > (long)MAX_ACCESSES || length != position + (usz)m_raw) return -1;
    int m = (int)m_raw;
    int[MAX_ACCESSES] accesses = zeroed;
    for (int i = 0; i < m; i += 1) {
        long key = input[position]; position += 1;
        if (key < 0 || key >= n) return -1;
        accesses[i] = (int)key;
    }

    int[MAX_NODES] stack_node = zeroed, stack_low = zeroed, stack_high = zeroed;
    bool[MAX_NODES] visited = zeroed;
    int stack_size = 1, visited_count = 0;
    stack_node[0] = root; stack_low[0] = -1; stack_high[0] = n;
    while (stack_size > 0) {
        stack_size -= 1;
        int node = stack_node[stack_size], low = stack_low[stack_size], high = stack_high[stack_size];
        if (visited[node] || node <= low || node >= high) return -1;
        visited[node] = true; visited_count += 1;
        if (left[node] >= 0) {
            stack_node[stack_size] = left[node]; stack_low[stack_size] = low; stack_high[stack_size] = node; stack_size += 1;
        }
        if (right[node] >= 0) {
            stack_node[stack_size] = right[node]; stack_low[stack_size] = node; stack_high[stack_size] = high; stack_size += 1;
        }
    }
    if (visited_count != n) return -1;

    long bound = 0;
    for (int pivot = 0; pivot < n; pivot += 1) {
        int previous = -1;
        for (int i = 0; i < m; i += 1) {
            int key = accesses[i], ancestor = key;
            while (ancestor >= 0 && ancestor != pivot) ancestor = parent[ancestor];
            if (ancestor == pivot) {
                int side = key <= pivot ? 0 : 1;
                if (previous >= 0 && side != previous) bound += 1;
                previous = side;
            }
        }
    }
    if (output == null || capacity < 8) return -2;
    char[8] staged;
    store_i64_le(&staged[0], bound);
    for (usz byte = 0; byte < 8; byte += 1) output[byte] = staged[byte];
    return 8;
}
