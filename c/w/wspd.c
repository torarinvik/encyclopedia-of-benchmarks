#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 8
#define MAX_NODES 15
#define MAX_PAIRS 28
#define MAX_OUTPUT_BYTES 456

typedef struct { int left, right, count; uint64_t mask; double cx, cy, radius; } WspdNode;
typedef struct {
    int64_t x[MAX_POINTS], y[MAX_POINTS];
    WspdNode nodes[MAX_NODES];
    int next_node, pair_count, point_count, separation, overflow;
    uint64_t left_masks[MAX_PAIRS], right_masks[MAX_PAIRS];
} WspdContext;

static int point_less(const WspdContext *ctx, int a, int b, int axis)
{
    int64_t a0 = axis == 0 ? ctx->x[a] : ctx->y[a];
    int64_t b0 = axis == 0 ? ctx->x[b] : ctx->y[b];
    int64_t a1 = axis == 0 ? ctx->y[a] : ctx->x[a];
    int64_t b1 = axis == 0 ? ctx->y[b] : ctx->x[b];
    return a0 < b0 || (a0 == b0 && (a1 < b1 || (a1 == b1 && a < b)));
}

static int build_node(WspdContext *ctx, uint64_t mask)
{
    const int id = ctx->next_node++;
    WspdNode *node = &ctx->nodes[id];
    node->left = node->right = -1;
    node->mask = mask;
    node->count = 0;
    int members[MAX_POINTS], used = 0;
    int64_t min_x = 0, max_x = 0, min_y = 0, max_y = 0;
    for (int i = 0; i < ctx->point_count; ++i) if ((mask & (UINT64_C(1) << i)) != 0) {
        if (used == 0) { min_x = max_x = ctx->x[i]; min_y = max_y = ctx->y[i]; }
        else {
            if (ctx->x[i] < min_x) min_x = ctx->x[i];
            if (ctx->x[i] > max_x) max_x = ctx->x[i];
            if (ctx->y[i] < min_y) min_y = ctx->y[i];
            if (ctx->y[i] > max_y) max_y = ctx->y[i];
        }
        members[used++] = i;
    }
    node->count = used;
    node->cx = ((double)min_x + (double)max_x) / 2.0;
    node->cy = ((double)min_y + (double)max_y) / 2.0;
    const double half_x = ((double)max_x - (double)min_x) / 2.0;
    const double half_y = ((double)max_y - (double)min_y) / 2.0;
    node->radius = sqrt(half_x * half_x + half_y * half_y);
    if (used == 1) return id;

    const int axis = max_x - min_x >= max_y - min_y ? 0 : 1;
    for (int i = 1; i < used; ++i) {
        const int value = members[i];
        int j = i;
        while (j > 0 && point_less(ctx, value, members[j - 1], axis)) {
            members[j] = members[j - 1]; --j;
        }
        members[j] = value;
    }
    uint64_t left_mask = 0, right_mask = 0;
    const int middle = used / 2;
    for (int i = 0; i < used; ++i)
        if (i < middle) left_mask |= UINT64_C(1) << members[i];
        else right_mask |= UINT64_C(1) << members[i];
    const int left = build_node(ctx, left_mask);
    const int right = build_node(ctx, right_mask);
    ctx->nodes[id].left = left;
    ctx->nodes[id].right = right;
    return id;
}

static int well_separated(const WspdContext *ctx, int a, int b)
{
    const WspdNode *first = &ctx->nodes[a], *second = &ctx->nodes[b];
    const double radius = first->radius > second->radius ? first->radius : second->radius;
    const double dx = first->cx - second->cx, dy = first->cy - second->cy;
    const double distance = sqrt(dx * dx + dy * dy);
    return distance - 2.0 * radius > (double)ctx->separation * radius;
}

static void cross_nodes(WspdContext *ctx, int a, int b)
{
    if (ctx->overflow) return;
    if (well_separated(ctx, a, b)) {
        if (ctx->pair_count >= MAX_PAIRS) { ctx->overflow = 1; return; }
        ctx->left_masks[ctx->pair_count] = ctx->nodes[a].mask;
        ctx->right_masks[ctx->pair_count] = ctx->nodes[b].mask;
        ++ctx->pair_count;
        return;
    }
    if (ctx->nodes[a].radius > ctx->nodes[b].radius) {
        cross_nodes(ctx, ctx->nodes[a].left, b);
        cross_nodes(ctx, ctx->nodes[a].right, b);
    } else {
        cross_nodes(ctx, a, ctx->nodes[b].left);
        cross_nodes(ctx, a, ctx->nodes[b].right);
    }
}

static void visit_node(WspdContext *ctx, int node)
{
    const int left = ctx->nodes[node].left, right = ctx->nodes[node].right;
    if (left < 0) return;
    visit_node(ctx, left);
    visit_node(ctx, right);
    cross_nodes(ctx, left, right);
}

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)bits; bits >>= 8; }
}

int64_t wspd(const int64_t *values, size_t length, uint8_t *output, size_t capacity)
{
    if (values == NULL || length < 4 || length > 18 || values[0] < 1 || values[0] > MAX_POINTS ||
        values[1] < 1 || values[1] > 8 || length != 2 + 2 * (size_t)values[0]) return -1;
    WspdContext ctx = {0};
    ctx.point_count = (int)values[0]; ctx.separation = (int)values[1];
    for (int i = 0; i < ctx.point_count; ++i) {
        const int64_t x = values[2 + 2 * i], y = values[3 + 2 * i];
        if (x < -1000 || x > 1000 || y < -1000 || y > 1000) return -1;
        for (int j = 0; j < i; ++j)
            if (ctx.x[j] == x && ctx.y[j] == y) return -1;
        ctx.x[i] = x; ctx.y[i] = y;
    }
    uint64_t all_points = (UINT64_C(1) << ctx.point_count) - 1;
    const int root = build_node(&ctx, all_points);
    visit_node(&ctx, root);
    if (ctx.overflow) return -2;
    const size_t required = 8 + 16 * (size_t)ctx.pair_count;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    put_i64(staged, 0, ctx.pair_count);
    for (int i = 0; i < ctx.pair_count; ++i) {
        put_i64(staged, 8 + 16 * (size_t)i, (int64_t)ctx.left_masks[i]);
        put_i64(staged, 16 + 16 * (size_t)i, (int64_t)ctx.right_masks[i]);
    }
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}
