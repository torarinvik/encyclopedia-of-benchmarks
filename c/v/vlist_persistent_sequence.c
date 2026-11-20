#include <stddef.h>
#include <stdint.h>

enum {
    MAX_Q = 48, MAX_CONS = 32, MAX_ROOTS = 49, MAX_BLOCKS = 6,
    MAX_SLOTS = 63, MAX_PARSEABLE = 146, MAX_OUTPUT = 384
};

typedef struct {
    int32_t previous_block;
    int32_t previous_offset;
    int32_t capacity;
    int32_t last_used;
    int32_t base;
} block_t;

typedef struct {
    block_t blocks[MAX_BLOCKS];
    int64_t data[MAX_SLOTS];
    int32_t root_block[MAX_ROOTS];
    int32_t root_offset[MAX_ROOTS];
    int32_t block_count;
    int32_t root_count;
    int32_t slot_count;
    int32_t cons_count;
    int64_t results[MAX_Q];
} context_t;

static int64_t list_length(const context_t *ctx, int32_t root) {
    int32_t block_id = ctx->root_block[root];
    int32_t offset = ctx->root_offset[root];
    int64_t total = 0;
    while (block_id >= 0) {
        if (block_id >= ctx->block_count || offset < 0 ||
            offset > ctx->blocks[block_id].last_used) return -1;
        const block_t *block = &ctx->blocks[block_id];
        total += (int64_t)offset + 1;
        block_id = block->previous_block;
        offset = block->previous_offset;
    }
    return total;
}

static int64_t list_nth(const context_t *ctx, int32_t root, int64_t index) {
    int32_t block_id = ctx->root_block[root];
    int32_t offset = ctx->root_offset[root];
    int64_t remaining = index;
    while (block_id >= 0) {
        if (block_id >= ctx->block_count || offset < 0 ||
            offset > ctx->blocks[block_id].last_used) return INT64_MIN;
        const block_t *block = &ctx->blocks[block_id];
        if (remaining <= offset)
            return ctx->data[block->base + offset - (int32_t)remaining];
        remaining -= (int64_t)offset + 1;
        block_id = block->previous_block;
        offset = block->previous_offset;
    }
    return INT64_MIN;
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) {
        output[offset + i] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t vlist_persistent_sequence(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_PARSEABLE) return -1;
    const int64_t q_word = input[0];
    if (q_word < 1 || q_word > MAX_Q || length != 1 + 3 * (size_t)q_word) return -1;
    const size_t q = (size_t)q_word;

    context_t ctx = {0};
    ctx.root_count = 1;
    for (int32_t i = 0; i < MAX_ROOTS; ++i) {
        ctx.root_block[i] = -1;
        ctx.root_offset[i] = -1;
    }
    int query_phase = 0;
    size_t at = 1;
    for (size_t op = 0; op < q; ++op) {
        const int64_t tag = input[at++];
        const int64_t root_word = input[at++];
        const int64_t arg = input[at++];
        if (tag < 0 || tag > 3 || root_word < 0 || root_word >= ctx.root_count) return -1;
        const int32_t root = (int32_t)root_word;
        if (tag == 0) {
            if (query_phase || root != ctx.root_count - 1 || ctx.cons_count >= MAX_CONS ||
                arg < -1000000 || arg > 1000000) return -1;
            int32_t block_id = ctx.root_block[root];
            int32_t offset = ctx.root_offset[root];
            if (block_id < 0) {
                if (ctx.cons_count != 0 || ctx.block_count != 0 || ctx.slot_count >= MAX_SLOTS) return -1;
                block_t *block = &ctx.blocks[ctx.block_count];
                block->previous_block = -1;
                block->previous_offset = -1;
                block->capacity = 1;
                block->last_used = 0;
                block->base = ctx.slot_count++;
                ctx.data[block->base] = arg;
                block_id = ctx.block_count++;
                offset = 0;
            } else {
                if (block_id >= ctx.block_count || offset != ctx.blocks[block_id].last_used) return -1;
                block_t *block = &ctx.blocks[block_id];
                if (offset + 1 < block->capacity) {
                    ++offset;
                    ctx.data[block->base + offset] = arg;
                    block->last_used = offset;
                } else {
                    const int32_t next_capacity = block->capacity * 2;
                    if (ctx.block_count >= MAX_BLOCKS ||
                        ctx.slot_count + next_capacity > MAX_SLOTS) return -1;
                    block_t *next = &ctx.blocks[ctx.block_count];
                    next->previous_block = block_id;
                    next->previous_offset = offset;
                    next->capacity = next_capacity;
                    next->last_used = 0;
                    next->base = ctx.slot_count;
                    ctx.data[next->base] = arg;
                    ctx.slot_count += next_capacity;
                    block_id = ctx.block_count++;
                    offset = 0;
                }
            }
            if (ctx.root_count >= MAX_ROOTS) return -1;
            ctx.root_block[ctx.root_count] = block_id;
            ctx.root_offset[ctx.root_count] = offset;
            ctx.results[op] = ctx.root_count++;
            ++ctx.cons_count;
        } else {
            query_phase = 1;
            if (tag == 1) {
                if (arg != -1 || list_length(&ctx, root) <= 0) return -1;
                int32_t block_id = ctx.root_block[root];
                int32_t offset = ctx.root_offset[root];
                if (offset > 0) {
                    --offset;
                } else {
                    const block_t *block = &ctx.blocks[block_id];
                    block_id = block->previous_block;
                    offset = block->previous_offset;
                }
                if (ctx.root_count >= MAX_ROOTS) return -1;
                ctx.root_block[ctx.root_count] = block_id;
                ctx.root_offset[ctx.root_count] = offset;
                ctx.results[op] = ctx.root_count++;
            } else if (tag == 2) {
                const int64_t n = list_length(&ctx, root);
                if (n < 0 || arg < 0 || arg >= n) return -1;
                const int64_t value = list_nth(&ctx, root, arg);
                if (value == INT64_MIN) return -1;
                ctx.results[op] = value;
            } else {
                if (arg != -1) return -1;
                const int64_t n = list_length(&ctx, root);
                if (n < 0) return -1;
                ctx.results[op] = n;
            }
        }
    }

    const size_t bytes = q * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < q; ++i) store_i64_le(output, i * 8, ctx.results[i]);
    return (int64_t)bytes;
}
