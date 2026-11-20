module triangle_mesh_faces_from_edge_graph;

const MAX_VERTICES = 8;
const MAX_EDGES = 28;
const MAX_TRIANGLES = 56;
const MAX_INPUT_WORDS = 59;
const MAX_OUTPUT_WORDS = 170;

struct Triangle { int a; int b; int c; int e0; int e1; int e2; bool active; }

fn bool has_edge(Triangle* triangle, int edge) {
    return triangle.e0 == edge || triangle.e1 == edge || triangle.e2 == edge;
}

fn void select_triangle(int chosen, Triangle* triangles, int triangle_count,
        int[MAX_EDGES]* incidence, int[MAX_EDGES]* used,
        long[MAX_OUTPUT_WORDS]* staged, int* face_count) {
    Triangle* triangle = &triangles[chosen];
    triangle.active = false;
    (*staged)[2 + 3 * face_count[0]] = triangle.a;
    (*staged)[3 + 3 * face_count[0]] = triangle.b;
    (*staged)[4 + 3 * face_count[0]] = triangle.c;
    face_count[0]++;

    int[3] face_edges = {triangle.e0, triangle.e1, triangle.e2};
    int[3] saturated = {-1, -1, -1};
    int saturated_count = 0;
    for (int slot = 0; slot < 3; slot++) {
        int edge = face_edges[slot];
        (*incidence)[edge]--;
        (*used)[edge]++;
        if ((*used)[edge] == 2) { saturated[saturated_count] = edge; saturated_count++; }
    }
    for (int other = 0; other < triangle_count; other++) {
        if (!triangles[other].active) continue;
        bool remove = false;
        for (int slot = 0; slot < saturated_count; slot++)
            if (has_edge(&triangles[other], saturated[slot])) remove = true;
        if (remove) {
            triangles[other].active = false;
            (*incidence)[triangles[other].e0]--;
            (*incidence)[triangles[other].e1]--;
            (*incidence)[triangles[other].e2]--;
        }
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long triangle_mesh_faces_from_edge_graph(long* input, usz length,
        char* output, usz capacity) @export("triangle_mesh_faces_from_edge_graph") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    long vertex_word = input[0], edge_word = input[1];
    if (vertex_word < 3 || vertex_word > MAX_VERTICES || edge_word < 0 || edge_word > MAX_EDGES) return -1;
    int vertices = (int)vertex_word, edge_count = (int)edge_word;
    if (edge_count > vertices * (vertices - 1) / 2 || length != (usz)(2 + 2 * edge_count)) return -1;

    int[MAX_VERTICES][MAX_VERTICES] edge_index = zeroed;
    for (int a = 0; a < MAX_VERTICES; a++) for (int b = 0; b < MAX_VERTICES; b++) edge_index[a][b] = -1;
    int[MAX_VERTICES] vertex_degree = zeroed;
    for (int edge = 0; edge < edge_count; edge++) {
        long left_word = input[2 + 2 * edge], right_word = input[3 + 2 * edge];
        if (left_word < 0 || left_word >= vertices || right_word < 0 || right_word >= vertices || left_word == right_word) return -1;
        int left = (int)left_word, right = (int)right_word;
        if (left > right) { int swap = left; left = right; right = swap; }
        if (edge_index[left][right] >= 0) return -1;
        edge_index[left][right] = edge;
        edge_index[right][left] = edge;
        vertex_degree[left]++;
        vertex_degree[right]++;
    }

    Triangle[MAX_TRIANGLES] triangles = {};
    int triangle_count = 0;
    int[MAX_EDGES] incidence = zeroed;
    for (int a = 0; a < vertices; a++) for (int b = a + 1; b < vertices; b++)
        for (int c = b + 1; c < vertices; c++) {
            int e0 = edge_index[a][b], e1 = edge_index[a][c], e2 = edge_index[b][c];
            if (e0 >= 0 && e1 >= 0 && e2 >= 0) {
                triangles[triangle_count] = {a, b, c, e0, e1, e2, true};
                triangle_count++;
                incidence[e0]++; incidence[e1]++; incidence[e2]++;
            }
        }

    int[MAX_EDGES] used = zeroed;
    long[MAX_OUTPUT_WORDS] staged = zeroed;
    int face_count = 0;
    bool fallback_used = false;
    while (true) {
        int chosen = triangle_count;
        for (int index = 0; index < triangle_count; index++) {
            Triangle* t = &triangles[index];
            if (t.active && (vertex_degree[t.a] == 3 || vertex_degree[t.b] == 3 || vertex_degree[t.c] == 3)) { chosen = index; break; }
        }
        if (chosen < triangle_count) {
            select_triangle(chosen, &triangles[0], triangle_count, &incidence, &used, &staged, &face_count);
            continue;
        }

        bool[MAX_EDGES] forced = zeroed;
        for (int edge = 0; edge < edge_count; edge++) forced[edge] = incidence[edge] > 0 && incidence[edge] == 2 - used[edge];
        chosen = triangle_count;
        for (int index = 0; index < triangle_count; index++) {
            Triangle* t = &triangles[index];
            if (t.active && (forced[t.e0] || forced[t.e1] || forced[t.e2])) { chosen = index; break; }
        }
        if (chosen < triangle_count) {
            select_triangle(chosen, &triangles[0], triangle_count, &incidence, &used, &staged, &face_count);
            continue;
        }

        int best_score = 3 * MAX_TRIANGLES + 1;
        chosen = triangle_count;
        for (int index = 0; index < triangle_count; index++) {
            Triangle* t = &triangles[index];
            if (!t.active) continue;
            int score = incidence[t.e0] + incidence[t.e1] + incidence[t.e2];
            if (score < best_score) { best_score = score; chosen = index; }
        }
        if (chosen == triangle_count) break;
        fallback_used = true;
        select_triangle(chosen, &triangles[0], triangle_count, &incidence, &used, &staged, &face_count);
    }

    bool complete = edge_count > 0;
    for (int edge = 0; edge < edge_count; edge++) if (used[edge] != 2) complete = false;
    staged[0] = (complete ? 0 : 2) + (fallback_used ? 1 : 0);
    staged[1] = face_count;
    usz output_bytes = (usz)(2 + 3 * face_count) * 8;
    if (output == null || capacity < output_bytes) return -2;
    for (usz word = 0; word < (usz)(2 + 3 * face_count); word++) store_i64_le(output, word * 8, staged[word]);
    return (long)output_bytes;
}
