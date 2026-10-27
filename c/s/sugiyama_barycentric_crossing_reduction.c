#include <stddef.h>
#include <stdint.h>

#define MAX_LAYERS 8
#define MAX_VERTICES 32
#define MAX_EDGES 128

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

static void positions_for_layer(int order[MAX_LAYERS][MAX_VERTICES],
                                const int sizes[MAX_LAYERS], int layer,
                                int position[MAX_VERTICES]) {
    for (int i = 0; i < sizes[layer]; ++i) position[order[layer][i]] = i;
}

static int reorder_layer(int order[MAX_LAYERS][MAX_VERTICES],
                         const int sizes[MAX_LAYERS], const int layer_of[MAX_VERTICES],
                         const int edge_u[MAX_EDGES], const int edge_v[MAX_EDGES], int edge_count,
                         int target, int fixed, int downward, int position[MAX_VERTICES]) {
    positions_for_layer(order, sizes, fixed, position);
    int old_rank[MAX_VERTICES] = {0}, numerator[MAX_VERTICES] = {0};
    int denominator[MAX_VERTICES] = {0};
    int *row = order[target];
    for (int i = 0; i < sizes[target]; ++i) old_rank[row[i]] = i;
    for (int e = 0; e < edge_count; ++e) {
        int u = edge_u[e], v = edge_v[e];
        if (downward && layer_of[u] == fixed && layer_of[v] == target) {
            numerator[v] += position[u];
            denominator[v] += 1;
        } else if (!downward && layer_of[u] == target && layer_of[v] == fixed) {
            numerator[u] += position[v];
            denominator[u] += 1;
        }
    }
    for (int i = 0; i < sizes[target]; ++i) {
        int vertex = row[i];
        if (denominator[vertex] == 0) {
            numerator[vertex] = old_rank[vertex];
            denominator[vertex] = 1;
        }
    }
    int changed = 0;
    for (int i = 1; i < sizes[target]; ++i) {
        int vertex = row[i], j = i;
        while (j > 0) {
            int previous = row[j - 1];
            int64_t left = (int64_t)numerator[vertex] * denominator[previous];
            int64_t right = (int64_t)numerator[previous] * denominator[vertex];
            if (left > right || (left == right && old_rank[vertex] > old_rank[previous])) break;
            row[j] = previous;
            --j;
        }
        row[j] = vertex;
    }
    for (int i = 0; i < sizes[target]; ++i)
        if (old_rank[row[i]] != i) changed = 1;
    positions_for_layer(order, sizes, target, position);
    return changed;
}

int64_t sugiyama_barycentric_crossing_reduction(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 299) return -1;
    int layers = (int)input[0], max_sweeps = (int)input[1];
    if (layers < 2 || layers > MAX_LAYERS || max_sweeps < 0 || max_sweeps > 16) return -1;
    int order[MAX_LAYERS][MAX_VERTICES] = {{0}};
    int sizes[MAX_LAYERS] = {0}, layer_of[MAX_VERTICES], position[MAX_VERTICES] = {0};
    int edge_u[MAX_EDGES] = {0}, edge_v[MAX_EDGES] = {0};
    for (int v = 0; v < MAX_VERTICES; ++v) layer_of[v] = -1;
    size_t at = 2;
    int total = 0;
    for (int layer = 0; layer < layers; ++layer) {
        if (at >= length) return -1;
        int64_t count = input[at++];
        if (count < 1 || count > MAX_VERTICES || at + (size_t)count > length) return -1;
        sizes[layer] = (int)count;
        total += (int)count;
        if (total > MAX_VERTICES) return -1;
        for (int i = 0; i < sizes[layer]; ++i) {
            int64_t id = input[at++];
            if (id < 0 || id >= MAX_VERTICES || layer_of[id] != -1) return -1;
            order[layer][i] = (int)id;
            layer_of[id] = layer;
        }
    }
    if (total < 2 || at >= length) return -1;
    int64_t edge_count0 = input[at++];
    if (edge_count0 < 0 || edge_count0 > MAX_EDGES || at + 2 * (size_t)edge_count0 != length) return -1;
    int edge_count = (int)edge_count0;
    for (int e = 0; e < edge_count; ++e) {
        int64_t u0 = input[at + 2 * (size_t)e], v0 = input[at + 2 * (size_t)e + 1];
        if (u0 < 0 || u0 >= MAX_VERTICES || v0 < 0 || v0 >= MAX_VERTICES) return -1;
        int u = (int)u0, v = (int)v0;
        if (layer_of[u] < 0 || layer_of[v] != layer_of[u] + 1) return -1;
        for (int j = 0; j < e; ++j)
            if (edge_u[j] == u && edge_v[j] == v) return -1;
        edge_u[e] = u;
        edge_v[e] = v;
    }

    int sweeps = 0;
    for (int pass = 0; pass < max_sweeps; ++pass) {
        int before[MAX_LAYERS][MAX_VERTICES];
        for (int l = 0; l < layers; ++l)
            for (int i = 0; i < sizes[l]; ++i) before[l][i] = order[l][i];
        for (int l = 0; l + 1 < layers; ++l)
            reorder_layer(order, sizes, layer_of, edge_u, edge_v, edge_count, l + 1, l, 1, position);
        for (int l = layers - 2; l >= 0; --l)
            reorder_layer(order, sizes, layer_of, edge_u, edge_v, edge_count, l, l + 1, 0, position);
        ++sweeps;
        int changed = 0;
        for (int l = 0; l < layers; ++l)
            for (int i = 0; i < sizes[l]; ++i)
                if (before[l][i] != order[l][i]) changed = 1;
        if (!changed) break;
    }
    for (int l = 0; l < layers; ++l) positions_for_layer(order, sizes, l, position);
    int64_t crossings = 0;
    for (int i = 0; i < edge_count; ++i)
        for (int j = i + 1; j < edge_count; ++j) {
            if (layer_of[edge_u[i]] != layer_of[edge_u[j]]) continue;
            if ((position[edge_u[i]] - position[edge_u[j]]) *
                (position[edge_v[i]] - position[edge_v[j]]) < 0) ++crossings;
        }
    size_t bytes = 8 * ((size_t)total + 2);
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, sweeps);
    put_i64(output, 1, crossings);
    size_t word = 2;
    for (int l = 0; l < layers; ++l)
        for (int i = 0; i < sizes[l]; ++i) put_i64(output, word++, order[l][i]);
    return (int64_t)bytes;
}
