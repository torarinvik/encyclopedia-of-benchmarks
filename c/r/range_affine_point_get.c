#include <stddef.h>
#include <stdint.h>

#define MAX_N 256u
#define MAX_Q 256u
#define MAX_BASE 256u
#define MAX_TREE (2u * MAX_BASE)
#define MAX_PARSEABLE_INPUT (2u + MAX_N + 5u * MAX_Q + 1u)
#define MAX_OUTPUT_BYTES (8u * MAX_Q)
#define MOD INT64_C(998244353)

typedef struct {
    int64_t kind, left, right, multiplier, offset;
} operation_t;

static void apply_tag(int64_t *mul, int64_t *add, size_t node,
                      int64_t multiplier, int64_t offset)
{
    add[node] = (multiplier * add[node] + offset) % MOD;
    mul[node] = (multiplier * mul[node]) % MOD;
}

static void push(int64_t *mul, int64_t *add, size_t node)
{
    if (mul[node] != 1 || add[node] != 0) {
        apply_tag(mul, add, 2u * node, mul[node], add[node]);
        apply_tag(mul, add, 2u * node + 1u, mul[node], add[node]);
        mul[node] = 1;
        add[node] = 0;
    }
}

static void range_apply(int64_t *mul, int64_t *add, size_t node,
                        size_t segment_left, size_t segment_right,
                        size_t left, size_t right,
                        int64_t multiplier, int64_t offset)
{
    if (right <= segment_left || segment_right <= left) return;
    if (left <= segment_left && segment_right <= right) {
        apply_tag(mul, add, node, multiplier, offset);
        return;
    }
    push(mul, add, node);
    const size_t middle = segment_left + (segment_right - segment_left) / 2u;
    range_apply(mul, add, 2u * node, segment_left, middle,
                left, right, multiplier, offset);
    range_apply(mul, add, 2u * node + 1u, middle, segment_right,
                left, right, multiplier, offset);
}

static int64_t point_get(int64_t *mul, int64_t *add, const int64_t *initial,
                         size_t node, size_t segment_left, size_t segment_right,
                         size_t index)
{
    if (segment_right - segment_left == 1u)
        return (mul[node] * initial[index] + add[node]) % MOD;
    push(mul, add, node);
    const size_t middle = segment_left + (segment_right - segment_left) / 2u;
    if (index < middle)
        return point_get(mul, add, initial, 2u * node, segment_left, middle, index);
    return point_get(mul, add, initial, 2u * node + 1u, middle, segment_right, index);
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8u; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8u * byte));
}

int64_t range_affine_point_get(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2u || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_N ||
        input[1] < 0 || input[1] > (int64_t)MAX_Q) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (2u + n > length) return -1;
    int64_t initial[MAX_N];
    operation_t operations[MAX_Q];
    for (size_t i = 0; i < n; ++i) {
        initial[i] = input[2u + i];
        if (initial[i] < 0 || initial[i] >= MOD) return -1;
    }
    size_t cursor = 2u + n, query_count = 0;
    for (size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        const int64_t kind = input[cursor++];
        if (kind == 0) {
            if (cursor + 4u > length) return -1;
            const int64_t left = input[cursor], right = input[cursor + 1u];
            const int64_t multiplier = input[cursor + 2u], offset = input[cursor + 3u];
            cursor += 4u;
            if (left < 0 || left >= right || right > (int64_t)n ||
                multiplier < 1 || multiplier >= MOD || offset < 0 || offset >= MOD) return -1;
            operations[i] = (operation_t){kind, left, right, multiplier, offset};
        } else if (kind == 1) {
            if (cursor >= length) return -1;
            const int64_t index = input[cursor++];
            if (index < 0 || index >= (int64_t)n) return -1;
            operations[i] = (operation_t){kind, index, 0, 0, 0};
            ++query_count;
        } else return -1;
    }
    if (cursor != length) return -1;
    const size_t output_bytes = 8u * query_count;
    if (output_bytes > 0u && (output == NULL || capacity < output_bytes)) return -2;

    size_t base = 1u;
    while (base < n) base *= 2u;
    int64_t mul[MAX_TREE], add[MAX_TREE];
    for (size_t node = 0; node < MAX_TREE; ++node) { mul[node] = 1; add[node] = 0; }
    size_t answer = 0;
    for (size_t i = 0; i < q; ++i) {
        const operation_t operation = operations[i];
        if (operation.kind == 0) {
            range_apply(mul, add, 1u, 0u, base, (size_t)operation.left,
                        (size_t)operation.right, operation.multiplier, operation.offset);
        } else {
            const int64_t value = point_get(mul, add, initial, 1u, 0u, base,
                                            (size_t)operation.left);
            store_i64_le(output, 8u * answer++, value);
        }
    }
    return (int64_t)output_bytes;
}
