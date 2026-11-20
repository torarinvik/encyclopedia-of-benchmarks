module canonical_order_maximal_plane_triangulation;

const usz MAX_N = 8, MAX_INPUT = 49, MAX_DARTS = 48;
struct Embedding {
    int n, u, v, w;
    int[MAX_N] degree;
    int[MAX_N][MAX_N] rotation;
    bool[MAX_N][MAX_N] adjacent;
}

fn int next_active(Embedding* g, bool[MAX_N] active, int source, int target) {
    int source_position = -1, remaining = 0;
    for (int i = 0; i < g.degree[target]; i++) {
        int neighbor = g.rotation[target][i];
        if (!active[neighbor]) continue;
        remaining++;
        if (neighbor == source) source_position = i;
    }
    if (remaining < 2 || source_position < 0) return -1;
    for (int step = 1; step <= g.degree[target]; step++) {
        int position = (source_position + step) % g.degree[target];
        int neighbor = g.rotation[target][position];
        if (active[neighbor]) return neighbor;
    }
    return -1;
}

fn int face_cycle(Embedding* g, bool[MAX_N] active, int first, int second, int[MAX_DARTS] cycle) {
    bool[MAX_N][MAX_N] seen = {};
    int source = first, target = second, length = 0;
    for (int step = 0; step < MAX_DARTS; step++) {
        if (source < 0 || source >= g.n || target < 0 || target >= g.n ||
            !active[source] || !active[target] || !g.adjacent[source][target] || seen[source][target]) return -1;
        seen[source][target] = true;
        cycle[length++] = source;
        int following = next_active(g, active, source, target);
        if (following < 0) return -1;
        source = target; target = following;
        if (source == first && target == second) return length;
    }
    return -1;
}

fn bool parse_embedding(long* input, usz length, Embedding* g) {
    if (input == null || length < 4 || length > MAX_INPUT) return false;
    long n_raw = input[0];
    if (n_raw < 3 || n_raw > MAX_N) return false;
    g.n = (int)n_raw;
    if (input[1] < 0 || input[1] >= n_raw || input[2] < 0 || input[2] >= n_raw ||
        input[3] < 0 || input[3] >= n_raw || input[1] == input[2] || input[1] == input[3] || input[2] == input[3]) return false;
    g.u = (int)input[1]; g.v = (int)input[2]; g.w = (int)input[3];
    usz offset = 4;
    int degree_sum = 0;
    for (int vertex = 0; vertex < g.n; vertex++) {
        if (offset >= length) return false;
        long degree_raw = input[offset++];
        if (degree_raw < 2 || degree_raw >= n_raw || offset + (usz)degree_raw > length) return false;
        int degree = (int)degree_raw;
        g.degree[vertex] = degree; degree_sum += degree;
        bool[MAX_N] row_seen = {};
        for (int rank = 0; rank < degree; rank++) {
            long neighbor_raw = input[offset++];
            if (neighbor_raw < 0 || neighbor_raw >= n_raw || neighbor_raw == vertex || row_seen[(int)neighbor_raw]) return false;
            int neighbor = (int)neighbor_raw;
            row_seen[neighbor] = true;
            g.rotation[vertex][rank] = neighbor;
            g.adjacent[vertex][neighbor] = true;
        }
    }
    if (offset != length || degree_sum != 6 * g.n - 12) return false;
    int edge_count = 0;
    for (int a = 0; a < g.n; a++) for (int b = 0; b < g.n; b++) {
        if (g.adjacent[a][b] != g.adjacent[b][a]) return false;
        if (a < b && g.adjacent[a][b]) edge_count++;
    }
    if (edge_count != 3 * g.n - 6) return false;
    bool[MAX_N] reached = {};
    int[MAX_N] stack = {};
    int stack_size = 1, reached_count = 0;
    stack[0] = 0; reached[0] = true;
    while (stack_size > 0) {
        int vertex = stack[--stack_size]; reached_count++;
        for (int neighbor = 0; neighbor < g.n; neighbor++) if (g.adjacent[vertex][neighbor] && !reached[neighbor]) {
            reached[neighbor] = true; stack[stack_size++] = neighbor;
        }
    }
    if (reached_count != g.n) return false;
    bool[MAX_N] all_active = {};
    for (int i = 0; i < g.n; i++) all_active[i] = true;
    bool[MAX_N][MAX_N] seen_dart = {};
    int face_count = 0, visited_darts = 0;
    for (int source = 0; source < g.n; source++) for (int target = 0; target < g.n; target++) {
        if (!g.adjacent[source][target] || seen_dart[source][target]) continue;
        int[MAX_DARTS] cycle = {};
        int face_length = face_cycle(g, all_active, source, target, cycle);
        if (face_length != 3) return false;
        face_count++;
        for (int i = 0; i < face_length; i++) {
            int a = cycle[i], b = cycle[(i + 1) % face_length];
            if (seen_dart[a][b]) return false;
            seen_dart[a][b] = true; visited_darts++;
        }
    }
    if (face_count != 2 * g.n - 4 || visited_darts != 6 * g.n - 12) return false;
    int[MAX_DARTS] outer = {};
    return face_cycle(g, all_active, g.u, g.v, outer) == 3 && outer[0] == g.u && outer[1] == g.v && outer[2] == g.w;
}

fn int boundary_path(Embedding* g, bool[MAX_N] active, int[MAX_N] path) {
    int[MAX_DARTS] cycle = {};
    int length = face_cycle(g, active, g.u, g.v, cycle);
    if (length < 3) return -1;
    int count = 0; path[count++] = g.u;
    for (int i = length - 1; i >= 2; i--) path[count++] = cycle[i];
    path[count++] = g.v;
    return count;
}

fn int peel_choice(Embedding* g, int[MAX_N] path, int length) {
    bool[MAX_N][MAX_N] chord = {};
    int chord_count = 0;
    for (int left = 0; left < length; left++) for (int right = left + 2; right < length; right++) {
        if (left == 0 && right == length - 1) continue;
        if (g.adjacent[path[left]][path[right]]) { chord[left][right] = true; chord_count++; }
    }
    bool[MAX_N] eligible = {};
    if (chord_count == 0) {
        for (int i = 1; i + 1 < length; i++) eligible[path[i]] = true;
    } else {
        for (int left = 0; left < length; left++) for (int right = left + 2; right < length; right++) {
            if (!chord[left][right]) continue;
            bool minimal = true;
            for (int a = left; a < right && minimal; a++) for (int b = a + 2; b <= right; b++)
                if (chord[a][b] && (a != left || b != right)) minimal = false;
            if (minimal) for (int i = left + 1; i < right; i++) eligible[path[i]] = true;
        }
    }
    int choice = -1;
    for (int vertex = 0; vertex < g.n; vertex++) if (eligible[vertex] && (choice < 0 || vertex < choice)) choice = vertex;
    return choice;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long canonical_order_maximal_plane_triangulation(long* input, usz length, char* output, usz capacity)
    @export("canonical_order_maximal_plane_triangulation") {
    Embedding g = {};
    if (!parse_embedding(input, length, &g)) return -1;
    bool[MAX_N] active = {};
    for (int i = 0; i < g.n; i++) active[i] = true;
    int[MAX_N] removals = {};
    int removed = 0;
    if (g.n > 3) {
        active[g.w] = false; removals[removed++] = g.w;
        int[MAX_N] path = {};
        int path_length = boundary_path(&g, active, path);
        if (path_length < 3) return -1;
        int active_count = g.n - 1;
        while (active_count > 3) {
            int choice = peel_choice(&g, path, path_length);
            if (choice < 0 || choice == g.u || choice == g.v || !active[choice]) return -1;
            active[choice] = false; removals[removed++] = choice; active_count--;
            path_length = boundary_path(&g, active, path);
            if (path_length < 3) return -1;
        }
        if (path_length != 3 || path[0] != g.u || path[2] != g.v) return -1;
    }
    long[MAX_N + 1] words = {};
    words[0] = g.n; words[1] = g.u; words[2] = g.v;
    int count = 3;
    if (g.n == 3) words[count++] = g.w;
    else {
        int third = -1;
        for (int vertex = 0; vertex < g.n; vertex++) if (active[vertex] && vertex != g.u && vertex != g.v) third = vertex;
        if (third < 0) return -1;
        words[count++] = third;
        for (int i = removed - 1; i >= 0; i--) words[count++] = removals[i];
    }
    if (count != g.n + 1 || words[count - 1] != g.w) return -1;
    usz required = 8 * (usz)count;
    if (output == null || capacity < required) return -2;
    for (int i = 0; i < count; i++) write_i64_le(output, 8 * (usz)i, words[i]);
    return (long)required;
}
