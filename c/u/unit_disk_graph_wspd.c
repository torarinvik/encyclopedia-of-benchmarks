#include <stddef.h>
#include <stdint.h>

enum { MAX_POINTS = 8, MAX_PAIRS = 28, MAX_INPUT = 18, MAX_OUTPUT = 456 };

typedef struct {
    int count;
    int64_t distance[MAX_POINTS][MAX_POINTS];
    int separation;
    int pair_count;
    uint64_t left[MAX_PAIRS];
    uint64_t right[MAX_PAIRS];
} Context;

static int popcount(uint64_t mask)
{
    int count = 0;
    while (mask) { count += (int)(mask & 1u); mask >>= 1; }
    return count;
}

static void split_mask(uint64_t mask, uint64_t *left, uint64_t *right)
{
    const int half = popcount(mask) / 2;
    int seen = 0;
    *left = *right = 0;
    for (int i = 0; i < MAX_POINTS; ++i) if (mask & (UINT64_C(1) << i)) {
        if (seen++ < half) *left |= UINT64_C(1) << i;
        else *right |= UINT64_C(1) << i;
    }
}

static int64_t diameter(const Context *ctx, uint64_t mask)
{
    int64_t result = 0;
    for (int i = 0; i < ctx->count; ++i) if (mask & (UINT64_C(1) << i))
        for (int j = i + 1; j < ctx->count; ++j) if (mask & (UINT64_C(1) << j))
            if (ctx->distance[i][j] > result) result = ctx->distance[i][j];
    return result;
}

static int64_t set_distance(const Context *ctx, uint64_t a, uint64_t b)
{
    int64_t result = INT64_MAX;
    for (int i = 0; i < ctx->count; ++i) if (a & (UINT64_C(1) << i))
        for (int j = 0; j < ctx->count; ++j) if (b & (UINT64_C(1) << j))
            if (ctx->distance[i][j] < result) result = ctx->distance[i][j];
    return result;
}

static void cross(Context *ctx, uint64_t a, uint64_t b)
{
    const int64_t da = diameter(ctx, a), db = diameter(ctx, b);
    const int64_t dmin = set_distance(ctx, a, b);
    const int64_t dmax = da > db ? da : db;
    if (dmin >= (int64_t)ctx->separation * dmax) {
        if (ctx->pair_count < MAX_PAIRS) {
            ctx->left[ctx->pair_count] = a;
            ctx->right[ctx->pair_count] = b;
            ++ctx->pair_count;
        }
        return;
    }
    if (popcount(a) >= popcount(b) && popcount(a) > 1) {
        uint64_t left, right;
        split_mask(a, &left, &right);
        cross(ctx, left, b);
        cross(ctx, right, b);
    } else {
        uint64_t left, right;
        split_mask(b, &left, &right);
        cross(ctx, a, left);
        cross(ctx, a, right);
    }
}

static void visit(Context *ctx, uint64_t mask)
{
    if (popcount(mask) < 2) return;
    uint64_t left, right;
    split_mask(mask, &left, &right);
    visit(ctx, left);
    visit(ctx, right);
    cross(ctx, left, right);
}

static void put_i64(uint8_t *out, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)bits; bits >>= 8; }
}

int64_t unit_disk_graph_wspd(const int64_t *values, size_t length, uint8_t *output, size_t capacity)
{
    if (!values || length < 4 || length > MAX_INPUT || values[0] < 1 || values[0] > MAX_POINTS ||
        values[1] < 1 || values[1] > 8 || length != 2 + 2 * (size_t)values[0]) return -1;
    Context ctx = {0};
    ctx.count = (int)values[0];
    ctx.separation = (int)values[1];
    int64_t x[MAX_POINTS], y[MAX_POINTS];
    for (int i = 0; i < ctx.count; ++i) {
        x[i] = values[2 + 2 * i]; y[i] = values[3 + 2 * i];
        if (x[i] < -8 || x[i] > 8 || y[i] < -8 || y[i] > 8) return -1;
        for (int j = 0; j < i; ++j) if (x[i] == x[j] && y[i] == y[j]) return -1;
    }
    for (int i = 0; i < ctx.count; ++i) for (int j = 0; j < ctx.count; ++j)
        ctx.distance[i][j] = i == j ? 0 : INT64_MAX / 4;
    for (int i = 0; i < ctx.count; ++i) for (int j = i + 1; j < ctx.count; ++j) {
        const int64_t dx = x[i] - x[j], dy = y[i] - y[j];
        if (dx * dx + dy * dy <= 1) ctx.distance[i][j] = ctx.distance[j][i] = 1;
    }
    for (int k = 0; k < ctx.count; ++k) for (int i = 0; i < ctx.count; ++i)
        for (int j = 0; j < ctx.count; ++j)
            if (ctx.distance[i][k] + ctx.distance[k][j] < ctx.distance[i][j])
                ctx.distance[i][j] = ctx.distance[i][k] + ctx.distance[k][j];
    for (int i = 0; i < ctx.count; ++i) for (int j = 0; j < ctx.count; ++j)
        if (ctx.distance[i][j] >= INT64_MAX / 8) return -1;
    visit(&ctx, (UINT64_C(1) << ctx.count) - 1);
    const size_t required = 8 + 16 * (size_t)ctx.pair_count;
    uint8_t staged[MAX_OUTPUT] = {0};
    put_i64(staged, 0, ctx.pair_count);
    for (int i = 0; i < ctx.pair_count; ++i) {
        put_i64(staged, 8 + 16 * (size_t)i, (int64_t)ctx.left[i]);
        put_i64(staged, 16 + 16 * (size_t)i, (int64_t)ctx.right[i]);
    }
    if (!output || capacity < required) return -2;
    for (size_t i = 0; i < required; ++i) output[i] = staged[i];
    return (int64_t)required;
}
