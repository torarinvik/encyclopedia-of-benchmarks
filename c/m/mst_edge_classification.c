#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 12
#define MAX_EDGES 24
#define MAX_INPUT_LENGTH (2 + 3 * MAX_EDGES + 1)

static int find_root(int *parent, int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

static void join_roots(int *parent, int left, int right) {
    const int a = find_root(parent, left);
    const int b = find_root(parent, right);
    if (a != b) parent[b] = a;
}

static int alternative_path_exists(int vertex_count, const int *left,
        const int *right, const int *edge_id, int edge_count,
        int omitted_edge, int source, int target) {
    int seen[MAX_VERTICES] = {0};
    int queue[MAX_VERTICES];
    int head = 0, tail = 0;
    seen[source] = 1;
    queue[tail++] = source;
    while (head < tail) {
        const int vertex = queue[head++];
        if (vertex == target) return 1;
        for (int edge = 0; edge < edge_count; ++edge) {
            if (edge_id[edge] == omitted_edge) continue;
            int neighbor = -1;
            if (left[edge] == vertex) neighbor = right[edge];
            else if (right[edge] == vertex) neighbor = left[edge];
            if (neighbor >= 0 && !seen[neighbor]) {
                seen[neighbor] = 1;
                queue[tail++] = neighbor;
            }
        }
    }
    (void)vertex_count;
    return 0;
}

int64_t mst_edge_classification(const int64_t *input, size_t length,
        uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const int vertex_count = (int)input[0];
    const int edge_count = (int)input[1];
    if (length != (size_t)(2 + 3 * edge_count)) return -1;

    int left[MAX_EDGES], right[MAX_EDGES], weight[MAX_EDGES], order[MAX_EDGES];
    uint8_t classes[MAX_EDGES] = {0};
    for (int edge = 0; edge < edge_count; ++edge) {
        const int64_t u = input[2 + 3 * edge];
        const int64_t v = input[3 + 3 * edge];
        const int64_t w = input[4 + 3 * edge];
        if (u < 0 || u >= v || v >= vertex_count || w < 0 || w > 20) return -1;
        left[edge] = (int)u;
        right[edge] = (int)v;
        weight[edge] = (int)w;
        order[edge] = edge;
        for (int prior = 0; prior < edge; ++prior)
            if (left[prior] == left[edge] && right[prior] == right[edge]) return -1;
    }
    for (int i = 1; i < edge_count; ++i) {
        const int item = order[i];
        int j = i;
        while (j > 0 && (weight[order[j - 1]] > weight[item] ||
                (weight[order[j - 1]] == weight[item] && order[j - 1] > item))) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = item;
    }

    int parent[MAX_VERTICES];
    for (int vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = vertex;
    int start = 0;
    while (start < edge_count) {
        int stop = start + 1;
        const int group_weight = weight[order[start]];
        while (stop < edge_count && weight[order[stop]] == group_weight) ++stop;
        int q_left[MAX_EDGES], q_right[MAX_EDGES], q_id[MAX_EDGES];
        int q_count = 0;
        for (int position = start; position < stop; ++position) {
            const int id = order[position];
            const int a = find_root(parent, left[id]);
            const int b = find_root(parent, right[id]);
            if (a != b) {
                q_left[q_count] = a;
                q_right[q_count] = b;
                q_id[q_count] = id;
                ++q_count;
            }
        }
        for (int edge = 0; edge < q_count; ++edge)
            classes[q_id[edge]] = alternative_path_exists(vertex_count, q_left, q_right,
                q_id, q_count, q_id[edge], q_left[edge], q_right[edge]) ? 1 : 2;
        for (int position = start; position < stop; ++position) {
            const int id = order[position];
            join_roots(parent, left[id], right[id]);
        }
        start = stop;
    }
    const int representative = find_root(parent, 0);
    for (int vertex = 1; vertex < vertex_count; ++vertex)
        if (find_root(parent, vertex) != representative) return -1;
    if (output_capacity < (size_t)edge_count || (edge_count > 0 && output == NULL)) return -2;
    for (int edge = 0; edge < edge_count; ++edge) output[edge] = classes[edge];
    return edge_count;
}
