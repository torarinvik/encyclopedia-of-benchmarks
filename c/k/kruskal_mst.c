#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_VERTICES 64
#define MAX_EDGES (MAX_VERTICES * (MAX_VERTICES - 1) / 2)
#define MAX_VALID_INPUT_LENGTH (2 + 3 * MAX_EDGES)
#define MAX_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define WEIGHT_MIN (-1000000)
#define WEIGHT_MAX 1000000

#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

typedef struct {
    int left;
    int right;
    int32_t weight;
} weighted_edge;

static int compare_edges_by_weight(const void *left_pointer, const void *right_pointer)
{
    const weighted_edge *left = (const weighted_edge *)left_pointer;
    const weighted_edge *right = (const weighted_edge *)right_pointer;
    if (left->weight < right->weight) return -1;
    if (left->weight > right->weight) return 1;
    return 0;
}

static int find_root(int *parent, int vertex)
{
    int root = vertex;
    while (parent[root] != root) root = parent[root];
    while (parent[vertex] != vertex) {
        int next = parent[vertex];
        parent[vertex] = root;
        vertex = next;
    }
    return root;
}

static int union_sets(int *parent, int *rank, int left, int right)
{
    int left_root = find_root(parent, left);
    int right_root = find_root(parent, right);
    if (left_root == right_root) return 0;
    if (rank[left_root] < rank[right_root]) {
        parent[left_root] = right_root;
    } else {
        parent[right_root] = left_root;
        if (rank[left_root] == rank[right_root]) ++rank[left_root];
    }
    return 1;
}

static void hash_byte(uint64_t *hash, uint8_t byte)
{
    *hash = (*hash ^ byte) * FNV_PRIME;
}

static void hash_u16(uint64_t *hash, uint16_t value)
{
    for (unsigned byte = 0; byte < 2; ++byte) hash_byte(hash, (uint8_t)(value >> (8 * byte)));
}

static void hash_i32(uint64_t *hash, int32_t value)
{
    uint32_t bits = (uint32_t)value;
    for (unsigned byte = 0; byte < 4; ++byte) hash_byte(hash, (uint8_t)(bits >> (8 * byte)));
}

static void hash_i64(uint64_t *hash, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte) hash_byte(hash, (uint8_t)(bits >> (8 * byte)));
}

int64_t kruskal_mst(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    int vertex_count = (int)input[0];
    int edge_count = (int)input[1];
    if (length != (size_t)(2 + 3 * edge_count) || length > MAX_VALID_INPUT_LENGTH) return -1;
    int maximum_for_graph = vertex_count * (vertex_count - 1) / 2;
    if (edge_count > maximum_for_graph || (vertex_count == 1 && edge_count != 0) ||
        (vertex_count > 1 && edge_count < vertex_count - 1)) return -1;

    weighted_edge edges[MAX_EDGES];
    uint8_t seen_pairs[MAX_VERTICES][MAX_VERTICES] = {{0}};
    for (int index = 0; index < edge_count; ++index) {
        size_t offset = (size_t)2 + (size_t)index * 3;
        int64_t raw_left = input[offset];
        int64_t raw_right = input[offset + 1];
        int64_t raw_weight = input[offset + 2];
        if (raw_left < 0 || raw_left >= vertex_count || raw_right < 0 || raw_right >= vertex_count ||
            raw_left == raw_right || raw_weight < WEIGHT_MIN || raw_weight > WEIGHT_MAX) return -1;
        int left = (int)raw_left, right = (int)raw_right;
        int lower = left < right ? left : right;
        int upper = left < right ? right : left;
        if (seen_pairs[lower][upper]) return -1;
        seen_pairs[lower][upper] = 1;
        edges[index] = (weighted_edge){lower, upper, (int32_t)raw_weight};
    }

    qsort(edges, (size_t)edge_count, sizeof(edges[0]), compare_edges_by_weight);
    for (int index = 1; index < edge_count; ++index)
        if (edges[index - 1].weight == edges[index].weight) return -1;

    int parent[MAX_VERTICES], rank[MAX_VERTICES] = {0};
    for (int vertex = 0; vertex < vertex_count; ++vertex) parent[vertex] = vertex;
    weighted_edge accepted[MAX_VERTICES - 1];
    int accepted_count = 0;
    int64_t total_weight = 0;
    for (int index = 0; index < edge_count && accepted_count < vertex_count - 1; ++index) {
        if (union_sets(parent, rank, edges[index].left, edges[index].right)) {
            accepted[accepted_count++] = edges[index];
            total_weight += edges[index].weight;
        }
    }
    if (accepted_count != vertex_count - 1) return -1;

    uint64_t hash = FNV_OFFSET;
    hash_u16(&hash, (uint16_t)vertex_count);
    hash_u16(&hash, (uint16_t)accepted_count);
    for (int index = 0; index < accepted_count; ++index) {
        hash_u16(&hash, (uint16_t)accepted[index].left);
        hash_u16(&hash, (uint16_t)accepted[index].right);
        hash_i32(&hash, accepted[index].weight);
    }
    hash_i64(&hash, total_weight);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
