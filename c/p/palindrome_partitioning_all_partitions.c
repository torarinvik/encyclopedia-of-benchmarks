#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 12
#define OUT_I64_CAP 16000

typedef struct {
    const int64_t *text;
    size_t length;
    size_t ends[MAX_LENGTH];
    int64_t packed[OUT_I64_CAP];
    size_t used;
    size_t partitions;
} Context;

static int is_palindrome(const Context *ctx, size_t start, size_t end)
{
    while (start < end) {
        if (ctx->text[start] != ctx->text[end - 1]) return 0;
        ++start;
        --end;
    }
    return 1;
}

static void enumerate(Context *ctx, size_t start, size_t depth)
{
    if (start == ctx->length) {
        ++ctx->partitions;
        ctx->packed[ctx->used++] = (int64_t)depth;
        for (size_t i = 0; i < depth; ++i)
            ctx->packed[ctx->used++] = (int64_t)ctx->ends[i];
        return;
    }
    for (size_t end = start + 1; end <= ctx->length; ++end) {
        if (is_palindrome(ctx, start, end)) {
            ctx->ends[depth] = end;
            enumerate(ctx, end, depth + 1);
        }
    }
}

int64_t palindrome_partitioning_all_partitions(const int64_t *input, size_t input_length,
                                                uint8_t *output, size_t capacity)
{
    if (input == NULL || input_length < 1 || input[0] < 0 || input[0] > MAX_LENGTH ||
        input_length != (size_t)input[0] + 1) return -1;
    const size_t length = (size_t)input[0];
    for (size_t i = 0; i < length; ++i)
        if (input[i + 1] < 0 || input[i + 1] > 127) return -1;

    Context ctx = { .text = input + 1, .length = length, .used = 1 };
    enumerate(&ctx, 0, 0);
    ctx.packed[0] = (int64_t)ctx.partitions;
    const size_t required = ctx.used * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < ctx.used; ++i) {
        const uint64_t bits = (uint64_t)ctx.packed[i];
        for (size_t byte = 0; byte < 8; ++byte)
            output[8 * i + byte] = (uint8_t)(bits >> (8 * byte));
    }
    return (int64_t)required;
}
