#include <stddef.h>
#include <stdint.h>

#define CMS_MAX_DEPTH 4
#define CMS_MAX_WIDTH 8
#define CMS_MAX_OPS 16
#define CMS_PRIME INT64_C(2147483647)

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) output[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t count_min_sketch_affine(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 59) return -1;
    int64_t d64 = input[0], w64 = input[1], ops64 = input[2];
    if (d64 < 1 || d64 > CMS_MAX_DEPTH || w64 < 1 || w64 > CMS_MAX_WIDTH || ops64 < 0 || ops64 > CMS_MAX_OPS) return -1;
    size_t d = (size_t)d64, w = (size_t)w64, ops = (size_t)ops64;
    if (length != 3 + 2 * d + 3 * ops) return -1;
    int64_t a[CMS_MAX_DEPTH], b[CMS_MAX_DEPTH];
    for (size_t r = 0; r < d; ++r) {
        a[r] = input[3 + 2 * r]; b[r] = input[4 + 2 * r];
        if (a[r] < 1 || a[r] >= CMS_PRIME || b[r] < 0 || b[r] >= CMS_PRIME) return -1;
    }
    size_t query_count = 0, op_start = 3 + 2 * d;
    for (size_t op = 0; op < ops; ++op) {
        int64_t kind = input[op_start + 3 * op], key = input[op_start + 3 * op + 1], weight = input[op_start + 3 * op + 2];
        if (key < 0 || key > 1000000) return -1;
        if (kind == 0) { if (weight < 1 || weight > 1000000) return -1; }
        else if (kind == 1) { if (weight != 0) return -1; ++query_count; }
        else return -1;
    }
    int64_t table[CMS_MAX_DEPTH][CMS_MAX_WIDTH] = {{0}};
    int64_t staged[CMS_MAX_OPS]; size_t staged_count = 0;
    for (size_t op = 0; op < ops; ++op) {
        int64_t kind = input[op_start + 3 * op], key = input[op_start + 3 * op + 1], weight = input[op_start + 3 * op + 2];
        size_t slots[CMS_MAX_DEPTH];
        for (size_t r = 0; r < d; ++r) slots[r] = (size_t)(((a[r] * key + b[r]) % CMS_PRIME) % (int64_t)w);
        if (kind == 0) for (size_t r = 0; r < d; ++r) table[r][slots[r]] += weight;
        else {
            int64_t minimum = table[0][slots[0]];
            for (size_t r = 1; r < d; ++r) if (table[r][slots[r]] < minimum) minimum = table[r][slots[r]];
            staged[staged_count++] = minimum;
        }
    }
    size_t required = query_count * 8;
    if (capacity < required || (required > 0 && output == NULL)) return -2;
    for (size_t i = 0; i < staged_count; ++i) put_i64_le(output, 8 * i, staged[i]);
    return (int64_t)required;
}
