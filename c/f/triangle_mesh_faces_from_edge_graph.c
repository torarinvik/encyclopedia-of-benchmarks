#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_EDGES 28
#define MAX_TRIANGLES 56
#define MAX_INPUT_WORDS 59
#define MAX_OUTPUT_WORDS 170

typedef struct {
    int a, b, c;
    int e0, e1, e2;
    int active;
} Triangle;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int has_edge(const Triangle *triangle, int edge) {
    return triangle->e0 == edge || triangle->e1 == edge || triangle->e2 == edge;
}

static void select_triangle(size_t chosen, Triangle *triangles, size_t triangle_count,
        int *incidence, int *used, int64_t *staged, size_t *face_count) {
    Triangle *triangle = &triangles[chosen];
    triangle->active = 0;
    staged[2 + 3 * *face_count] = triangle->a;
    staged[3 + 3 * *face_count] = triangle->b;
    staged[4 + 3 * *face_count] = triangle->c;
    ++*face_count;

    const int face_edges[3] = {triangle->e0, triangle->e1, triangle->e2};
    int saturated[3] = {-1, -1, -1};
    size_t saturated_count = 0;
    for (size_t slot = 0; slot < 3; ++slot) {
        const int edge = face_edges[slot];
        --incidence[edge];
        ++used[edge];
        if (used[edge] == 2) saturated[saturated_count++] = edge;
    }
    for (size_t other = 0; other < triangle_count; ++other) {
        if (!triangles[other].active) continue;
        int remove = 0;
        for (size_t slot = 0; slot < saturated_count; ++slot)
            if (has_edge(&triangles[other], saturated[slot])) remove = 1;
        if (remove) {
            triangles[other].active = 0;
            --incidence[triangles[other].e0];
            --incidence[triangles[other].e1];
            --incidence[triangles[other].e2];
        }
    }
}

int64_t triangle_mesh_faces_from_edge_graph(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int64_t vertex_word = input[0];
    const int64_t edge_word = input[1];
    if (vertex_word < 3 || vertex_word > MAX_VERTICES || edge_word < 0 || edge_word > MAX_EDGES) return -1;
    const int vertices = (int)vertex_word;
    const int edge_count = (int)edge_word;
    if (edge_count > vertices * (vertices - 1) / 2 || length != (size_t)(2 + 2 * edge_count)) return -1;

    int edge_index[MAX_VERTICES][MAX_VERTICES];
    int vertex_degree[MAX_VERTICES] = {0};
    for (int a = 0; a < MAX_VERTICES; ++a)
        for (int b = 0; b < MAX_VERTICES; ++b) edge_index[a][b] = -1;
    for (int edge = 0; edge < edge_count; ++edge) {
        int64_t left_word = input[2 + 2 * edge];
        int64_t right_word = input[3 + 2 * edge];
        if (left_word < 0 || left_word >= vertices || right_word < 0 || right_word >= vertices || left_word == right_word) return -1;
        int left = (int)left_word, right = (int)right_word;
        if (left > right) { int swap = left; left = right; right = swap; }
        if (edge_index[left][right] >= 0) return -1;
        edge_index[left][right] = edge_index[right][left] = edge;
        ++vertex_degree[left];
        ++vertex_degree[right];
    }

    Triangle triangles[MAX_TRIANGLES];
    size_t triangle_count = 0;
    int incidence[MAX_EDGES] = {0};
    for (int a = 0; a < vertices; ++a) {
        for (int b = a + 1; b < vertices; ++b) {
            for (int c = b + 1; c < vertices; ++c) {
                const int e0 = edge_index[a][b], e1 = edge_index[a][c], e2 = edge_index[b][c];
                if (e0 >= 0 && e1 >= 0 && e2 >= 0) {
                    Triangle *triangle = &triangles[triangle_count++];
                    triangle->a = a; triangle->b = b; triangle->c = c;
                    triangle->e0 = e0; triangle->e1 = e1; triangle->e2 = e2;
                    triangle->active = 1;
                    ++incidence[e0]; ++incidence[e1]; ++incidence[e2];
                }
            }
        }
    }

    int used[MAX_EDGES] = {0};
    int64_t staged[MAX_OUTPUT_WORDS] = {0};
    size_t face_count = 0;
    int fallback_used = 0;
    for (;;) {
        size_t chosen = triangle_count;
        for (size_t index = 0; index < triangle_count; ++index) {
            const Triangle *triangle = &triangles[index];
            if (triangle->active && (vertex_degree[triangle->a] == 3 || vertex_degree[triangle->b] == 3 || vertex_degree[triangle->c] == 3)) {
                chosen = index;
                break;
            }
        }
        if (chosen < triangle_count) {
            select_triangle(chosen, triangles, triangle_count, incidence, used, staged, &face_count);
            continue;
        }

        int forced[MAX_EDGES] = {0};
        for (int edge = 0; edge < edge_count; ++edge)
            forced[edge] = incidence[edge] > 0 && incidence[edge] == 2 - used[edge];
        chosen = triangle_count;
        for (size_t index = 0; index < triangle_count; ++index) {
            const Triangle *triangle = &triangles[index];
            if (triangle->active && (forced[triangle->e0] || forced[triangle->e1] || forced[triangle->e2])) {
                chosen = index;
                break;
            }
        }
        if (chosen < triangle_count) {
            select_triangle(chosen, triangles, triangle_count, incidence, used, staged, &face_count);
            continue;
        }

        int best_score = 3 * MAX_TRIANGLES + 1;
        chosen = triangle_count;
        for (size_t index = 0; index < triangle_count; ++index) {
            const Triangle *triangle = &triangles[index];
            if (!triangle->active) continue;
            const int score = incidence[triangle->e0] + incidence[triangle->e1] + incidence[triangle->e2];
            if (score < best_score) { best_score = score; chosen = index; }
        }
        if (chosen == triangle_count) break;
        fallback_used = 1;
        select_triangle(chosen, triangles, triangle_count, incidence, used, staged, &face_count);
    }

    int complete = edge_count > 0;
    for (int edge = 0; edge < edge_count; ++edge)
        if (used[edge] != 2) complete = 0;
    staged[0] = (complete ? 0 : 2) + fallback_used;
    staged[1] = (int64_t)face_count;
    const size_t output_bytes = (2 + 3 * face_count) * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t word = 0; word < 2 + 3 * face_count; ++word)
        store_i64_le(output, word * 8, staged[word]);
    return (int64_t)output_bytes;
}
