#include <stddef.h>
#include <stdint.h>

#define PB_MAX_POINTS 8
#define PB_MAX_NODES 15
#define PB_LEAF_SIZE 2
#define PB_MAX_INPUT 34
#define PB_COORD_LIMIT 1000000

typedef struct { int64_t x, y; } PbPoint;
typedef struct {
    int left, right, start, count;
    int64_t min_x, min_y, max_x, max_y;
} PbNode;
typedef struct {
    PbPoint points[PB_MAX_POINTS];
    int order[PB_MAX_POINTS], scratch[PB_MAX_POINTS];
    PbNode nodes[PB_MAX_NODES];
    int node_count;
} PbTree;

static int pb_build(PbTree *tree, int start, int count)
{
    const int id = tree->node_count++;
    PbNode *node = &tree->nodes[id];
    node->left = node->right = -1;
    node->start = start;
    node->count = count;
    PbPoint first = tree->points[tree->order[start]];
    node->min_x = node->max_x = first.x;
    node->min_y = node->max_y = first.y;
    for (int i = 1; i < count; ++i) {
        PbPoint p = tree->points[tree->order[start + i]];
        if (p.x < node->min_x) node->min_x = p.x;
        if (p.x > node->max_x) node->max_x = p.x;
        if (p.y < node->min_y) node->min_y = p.y;
        if (p.y > node->max_y) node->max_y = p.y;
    }
    if (count <= PB_LEAF_SIZE) return id;

    const int axis = (node->max_x - node->min_x) > (node->max_y - node->min_y) ? 0 : 1;
    const int64_t midpoint_twice = axis == 0 ? node->min_x + node->max_x : node->min_y + node->max_y;
    int left_count = 0;
    for (int i = 0; i < count; ++i) {
        PbPoint p = tree->points[tree->order[start + i]];
        const int64_t coordinate_twice = 2 * (axis == 0 ? p.x : p.y);
        if (coordinate_twice < midpoint_twice) ++left_count;
    }
    if (left_count == 0 || left_count == count) {
        left_count = (count + 1) / 2;
        for (int i = 0; i < count; ++i) tree->scratch[i] = tree->order[start + i];
    } else {
        int l = 0, r = left_count;
        for (int i = 0; i < count; ++i) {
            const int index = tree->order[start + i];
            PbPoint p = tree->points[index];
            const int64_t coordinate_twice = 2 * (axis == 0 ? p.x : p.y);
            tree->scratch[coordinate_twice < midpoint_twice ? l++ : r++] = index;
        }
    }
    for (int i = 0; i < count; ++i) tree->order[start + i] = tree->scratch[i];
    const int left = pb_build(tree, start, left_count);
    const int right = pb_build(tree, start + left_count, count - left_count);
    tree->nodes[id].left = left;
    tree->nodes[id].right = right;
    tree->nodes[id].count = 0;
    return id;
}

static int64_t pb_box_distance(const PbNode *a, const PbNode *b)
{
    int64_t dx = 0, dy = 0;
    if (a->max_x < b->min_x) dx = b->min_x - a->max_x;
    else if (b->max_x < a->min_x) dx = a->min_x - b->max_x;
    if (a->max_y < b->min_y) dy = b->min_y - a->max_y;
    else if (b->max_y < a->min_y) dy = a->min_y - b->max_y;
    return dx * dx + dy * dy;
}

static void pb_search(const PbTree *a, int ai, const PbTree *b, int bi, int64_t *best)
{
    const PbNode *na = &a->nodes[ai], *nb = &b->nodes[bi];
    if (pb_box_distance(na, nb) > *best) return;
    const int a_leaf = na->left < 0, b_leaf = nb->left < 0;
    if (a_leaf && b_leaf) {
        for (int i = 0; i < na->count; ++i) {
            PbPoint p = a->points[a->order[na->start + i]];
            for (int j = 0; j < nb->count; ++j) {
                PbPoint q = b->points[b->order[nb->start + j]];
                int64_t dx = p.x - q.x, dy = p.y - q.y;
                int64_t distance = dx * dx + dy * dy;
                if (distance < *best) *best = distance;
            }
        }
    } else if (a_leaf) {
        const int left = nb->left, right = nb->right;
        if (pb_box_distance(na, &b->nodes[left]) < pb_box_distance(na, &b->nodes[right])) {
            pb_search(a, ai, b, left, best); pb_search(a, ai, b, right, best);
        } else {
            pb_search(a, ai, b, right, best); pb_search(a, ai, b, left, best);
        }
    } else if (b_leaf) {
        const int left = na->left, right = na->right;
        if (pb_box_distance(nb, &a->nodes[left]) < pb_box_distance(nb, &a->nodes[right])) {
            pb_search(a, left, b, bi, best); pb_search(a, right, b, bi, best);
        } else {
            pb_search(a, right, b, bi, best); pb_search(a, left, b, bi, best);
        }
    } else {
        int pairs[4][2] = {{na->left, nb->left}, {na->left, nb->right},
                           {na->right, nb->left}, {na->right, nb->right}};
        int64_t distances[4];
        for (int i = 0; i < 4; ++i) distances[i] = pb_box_distance(&a->nodes[pairs[i][0]], &b->nodes[pairs[i][1]]);
        for (int i = 1; i < 4; ++i) {
            int p0 = pairs[i][0], p1 = pairs[i][1]; int64_t d = distances[i]; int j = i;
            while (j > 0 && d < distances[j - 1]) {
                pairs[j][0] = pairs[j - 1][0]; pairs[j][1] = pairs[j - 1][1]; distances[j] = distances[j - 1]; --j;
            }
            pairs[j][0] = p0; pairs[j][1] = p1; distances[j] = d;
        }
        for (int i = 0; i < 4; ++i) pb_search(a, pairs[i][0], b, pairs[i][1], best);
    }
}

static void pb_write_i64(uint8_t *out, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (int i = 0; i < 8; ++i) out[i] = (uint8_t)(bits >> (8 * i));
}

int64_t pargeo_bichromatic_closest_pair(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 10 || length > PB_MAX_INPUT) return -1;
    const int64_t na64 = input[0], nb64 = input[1];
    if (na64 < 2 || na64 > PB_MAX_POINTS || nb64 < 2 || nb64 > PB_MAX_POINTS) return -1;
    const int na = (int)na64, nb = (int)nb64;
    if (length != (size_t)(2 + 2 * (na + nb))) return -1;
    for (size_t i = 2; i < length; ++i)
        if (input[i] < -PB_COORD_LIMIT || input[i] > PB_COORD_LIMIT) return -1;
    if (output == NULL || output_capacity < 8) return -2;

    PbTree a = {0}, b = {0};
    for (int i = 0; i < na; ++i) { a.points[i] = (PbPoint){input[2 + 2 * i], input[3 + 2 * i]}; a.order[i] = i; }
    const int b_offset = 2 + 2 * na;
    for (int i = 0; i < nb; ++i) { b.points[i] = (PbPoint){input[b_offset + 2 * i], input[b_offset + 2 * i + 1]}; b.order[i] = i; }
    const int root_a = pb_build(&a, 0, na), root_b = pb_build(&b, 0, nb);
    int64_t best = INT64_MAX;
    pb_search(&a, root_a, &b, root_b, &best);
    pb_write_i64(output, best);
    return 8;
}
