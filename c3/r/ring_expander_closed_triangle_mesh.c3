module ring_expander_closed_triangle_mesh;

const int MAX_N = 12, MAX_T = 20, MAX_C = 60, MAX_INPUT = 64;

fn int next_corner(int corner) { return 3 * (corner / 3) + (corner % 3 + 1) % 3; }
fn int prev_corner(int corner) { return 3 * (corner / 3) + (corner % 3 + 2) % 3; }
fn int corner_vertex(long[MAX_C]* faces, int corner) {
    return faces[3 * (corner / 3) + corner % 3].int();
}
fn void put_word(char* output, usz offset, long value) {
    ulong bits = value.ulong();
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn bool run(int n, int t, int seed, long[MAX_C]* faces, long[MAX_C]* trace,
            int* trace_count, ulong* vertex_mask, ulong* triangle_mask) {
    int[MAX_C] opposite = zeroed;
    bool[MAX_N][MAX_N][MAX_N] link = zeroed;
    bool[MAX_N] used = zeroed;
    u8[MAX_N][MAX_N] edge_count = zeroed;
    int[MAX_N][MAX_N] edge_first = zeroed;
    int[MAX_N][MAX_N] edge_second = zeroed;
    for (int a = 0; a < MAX_N; a++) for (int b = 0; b < MAX_N; b++) {
        edge_first[a][b] = -1;
        edge_second[a][b] = -1;
    }
    for (int ti = 0; ti < t; ti++) {
        int a = faces[3 * ti].int(), b = faces[3 * ti + 1].int(), c = faces[3 * ti + 2].int();
        used[a] = true; used[b] = true; used[c] = true;
        link[a][b][c] = true; link[a][c][b] = true;
        link[b][c][a] = true; link[b][a][c] = true;
        link[c][a][b] = true; link[c][b][a] = true;
        for (int j = 0; j < 3; j++) {
            int first = faces[3 * ti + (j + 1) % 3].int();
            int second = faces[3 * ti + (j + 2) % 3].int();
            int low = first < second ? first : second;
            int high = first < second ? second : first;
            u8 count = edge_count[low][high];
            if (count == 0) edge_first[low][high] = 3 * ti + j;
            else if (count == 1) edge_second[low][high] = 3 * ti + j;
            else return false;
            edge_count[low][high] = count + 1;
        }
    }
    for (int v = 0; v < n; v++) if (!used[v]) return false;

    for (int low = 0; low < n; low++) for (int high = low + 1; high < n; high++) {
        if (edge_count[low][high] == 0) continue;
        if (edge_count[low][high] != 2) return false;
        int a = edge_first[low][high], b = edge_second[low][high];
        int at = a / 3, aj = a % 3, bt = b / 3, bj = b % 3;
        int a0 = faces[3 * at + (aj + 1) % 3].int();
        int a1 = faces[3 * at + (aj + 2) % 3].int();
        int b0 = faces[3 * bt + (bj + 1) % 3].int();
        int b1 = faces[3 * bt + (bj + 2) % 3].int();
        if (a0 != b1 || a1 != b0) return false;
        opposite[a] = b;
        opposite[b] = a;
    }

    for (int v = 0; v < n; v++) {
        int start = -1;
        for (int w = 0; w < n; w++) {
            int degree = 0;
            for (int x = 0; x < n; x++) if (link[v][w][x]) degree++;
            if (degree > 0 && start < 0) start = w;
            if (degree > 0 && degree != 2) return false;
        }
        if (start < 0) return false;
        bool[MAX_N] seen = zeroed;
        int[MAX_N] queue = zeroed;
        int head = 0, tail = 0;
        seen[start] = true; queue[tail++] = start;
        while (head < tail) {
            int w = queue[head++];
            for (int x = 0; x < n; x++) if (link[v][w][x] && !seen[x]) { seen[x] = true; queue[tail++] = x; }
        }
        for (int w = 0; w < n; w++) {
            bool has_edge = false;
            for (int x = 0; x < n; x++) has_edge |= link[v][w][x];
            if (has_edge && !seen[w]) return false;
        }
    }

    bool[MAX_T] reached = zeroed;
    int[MAX_T] queue = zeroed;
    int head = 0, tail = 0;
    reached[0] = true; queue[tail++] = 0;
    while (head < tail) {
        int ti = queue[head++];
        for (int j = 0; j < 3; j++) {
            int other = opposite[3 * ti + j] / 3;
            if (!reached[other]) { reached[other] = true; queue[tail++] = other; }
        }
    }
    for (int ti = 0; ti < t; ti++) if (!reached[ti]) return false;

    bool[MAX_C] seen_corners = zeroed;
    *vertex_mask = 0; *triangle_mask = 0; *trace_count = 0;
    *vertex_mask |= 1ul << corner_vertex(faces, next_corner(seed));
    *vertex_mask |= 1ul << corner_vertex(faces, prev_corner(seed));
    int stop = opposite[seed], current = seed;
    while (current != stop) {
        if (current < 0 || current >= 3 * t || seen_corners[current] || *trace_count >= 3 * t) return false;
        seen_corners[current] = true;
        trace[*trace_count] = current;
        (*trace_count)++;
        int ti = current / 3, vertex = corner_vertex(faces, current);
        if (((*vertex_mask >> vertex) & 1ul) == 0) {
            *vertex_mask |= 1ul << vertex;
            *triangle_mask |= 1ul << ti;
        } else if (((*triangle_mask >> ti) & 1ul) == 0) current = opposite[current];
        current = opposite[prev_corner(current)];
    }
    true
}

fn long ring_expander_closed_triangle_mesh(long* input, usz length, char* output, usz capacity)
    @export("ring_expander_closed_triangle_mesh") {
    if (input == null || length < 15 || length > MAX_INPUT) return -1;
    long n64 = input[0], t64 = input[1], seed64 = input[2];
    if (n64 < 4 || n64 > MAX_N || t64 < 4 || t64 > MAX_T ||
        length != 3 + 3 * t64.usz() || seed64 < 0 || seed64 >= 3 * t64) return -1;
    int n = n64.int(), t = t64.int(), seed = seed64.int();
    long[MAX_C] faces = zeroed;
    for (int i = 0; i < 3 * t; i++) {
        long value = input[3 + i];
        if (value < 0 || value >= n64) return -1;
        faces[i] = value;
    }
    for (int ti = 0; ti < t; ti++)
        if (faces[3 * ti] == faces[3 * ti + 1] || faces[3 * ti + 1] == faces[3 * ti + 2] || faces[3 * ti + 2] == faces[3 * ti]) return -1;
    long[MAX_C] trace = zeroed;
    int trace_count = 0;
    ulong vertices = 0, triangles = 0;
    if (!run(n, t, seed, &faces, &trace, &trace_count, &vertices, &triangles)) return -1;
    usz words = 1 + trace_count.usz() + 2;
    usz bytes = 8 * words;
    if (output == null || capacity < bytes) return -2;
    put_word(output, 0, trace_count);
    for (int i = 0; i < trace_count; i++) put_word(output, 8 * (i + 1).usz(), trace[i]);
    put_word(output, 8 * (trace_count + 1).usz(), vertices.long());
    put_word(output, 8 * (trace_count + 2).usz(), triangles.long());
    bytes.long()
}
