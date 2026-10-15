#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define MAX_INPUT 2200
#define MAX_NODES 127

typedef struct {
    const int64_t *input;
    size_t length, output_length;
    uint8_t output[MAX_INPUT];
} context;

static int is_space(uint8_t value)
{
    return value == ' ' || (value >= '\t' && value <= '\r');
}

static int append(context *ctx, uint8_t value)
{
    if (ctx->output_length >= MAX_INPUT) return 0;
    ctx->output[ctx->output_length++] = value;
    return 1;
}

static int parse_integer(const int64_t *input, size_t start, size_t end, int32_t *result)
{
    while (start < end && is_space((uint8_t)input[start])) ++start;
    while (end > start && is_space((uint8_t)input[end - 1])) --end;
    if (start == end) return 0;
    int negative = 0;
    if (input[start] == '-' || input[start] == '+') {
        negative = input[start] == '-';
        ++start;
    }
    if (start == end) return 0;
    int64_t value = 0;
    const int64_t limit = negative ? INT64_C(2147483648) : INT64_C(2147483647);
    for (size_t i = start; i < end; ++i) {
        if (input[i] < '0' || input[i] > '9') return 0;
        const int digit = (int)(input[i] - '0');
        if (value > (limit - digit) / 10) return 0;
        value = value * 10 + digit;
    }
    *result = negative ? (int32_t)(-value) : (int32_t)value;
    return 1;
}

int64_t serialize_deserialize_binary_tree(const int64_t *values, size_t length,
                                           uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length == 0 || length > MAX_INPUT) return -1;
    for (size_t i = 0; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    context ctx = { .input = values, .length = length, .output_length = 0 };
    size_t position = 0, slots = 1, nodes = 0;
    while (position < length) {
        if (slots == 0) return -1;
        const size_t start = position;
        while (position < length && values[position] != ',') ++position;
        const size_t end = position;
        if (start == end) return -1;
        const int is_null = end - start == 4 && values[start] == 'n' && values[start + 1] == 'u' &&
                            values[start + 2] == 'l' && values[start + 3] == 'l';
        if (ctx.output_length != 0 && !append(&ctx, ',')) return -1;
        if (is_null) {
            if (!append(&ctx, 'n') || !append(&ctx, 'u') || !append(&ctx, 'l') || !append(&ctx, 'l')) return -1;
        } else {
            int32_t number;
            if (!parse_integer(values, start, end, &number) || ++nodes > MAX_NODES) return -1;
            char text[16];
            const int count = snprintf(text, sizeof(text), "%d", number);
            if (count <= 0) return -1;
            for (int i = 0; i < count; ++i) if (!append(&ctx, (uint8_t)text[i])) return -1;
        }
        --slots;
        if (!is_null) slots += 2;
        if (position < length) {
            ++position;
            if (position == length) return -1;
        }
    }
    if (slots != 0) return -1;
    if (output == NULL || output_capacity < ctx.output_length) return -2;
    for (size_t i = 0; i < ctx.output_length; ++i) output[i] = ctx.output[i];
    return (int64_t)ctx.output_length;
}
