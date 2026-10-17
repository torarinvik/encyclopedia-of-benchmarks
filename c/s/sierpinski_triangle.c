#include <stddef.h>
#include <stdint.h>

#define MAX_OUTPUT_BYTES 11616

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
    }
}

static void emit_segment(uint8_t *output, size_t *position,
                         int64_t x0, int64_t y0, int64_t x1, int64_t y1) {
    write_i64_le(output, *position, x0); *position += 8;
    write_i64_le(output, *position, y0); *position += 8;
    write_i64_le(output, *position, x1); *position += 8;
    write_i64_le(output, *position, y1); *position += 8;
}

static void draw_triangle(uint8_t *output, size_t *position,
                          int64_t x1, int64_t y1, int64_t x2, int64_t y2,
                          int64_t x3, int64_t y3, int64_t depth) {
    emit_segment(output, position, x1, y1, x2, y2);
    emit_segment(output, position, x2, y2, x3, y3);
    emit_segment(output, position, x3, y3, x1, y1);
    if (depth == 0) return;
    const int64_t abx = (x1 + x2) / 2, aby = (y1 + y2) / 2;
    const int64_t acx = (x1 + x3) / 2, acy = (y1 + y3) / 2;
    const int64_t bcx = (x2 + x3) / 2, bcy = (y2 + y3) / 2;
    draw_triangle(output, position, x1, y1, abx, aby, acx, acy, depth - 1);
    draw_triangle(output, position, x2, y2, abx, aby, bcx, bcy, depth - 1);
    draw_triangle(output, position, x3, y3, bcx, bcy, acx, acy, depth - 1);
}

int64_t sierpinski_triangle(const int64_t *input, size_t length,
                            uint8_t *output, size_t capacity) {
    if (input == NULL || length != 1) return -1;
    const int64_t depth = input[0];
    if (depth < 0 || depth > 4) return -1;
    size_t calls = 1;
    for (int64_t level = 0; level < depth; ++level) calls = calls * 3 + 1;
    const size_t needed = calls * 96;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < needed) return -2;
    size_t position = 0;
    draw_triangle(output, &position, -2800, -2000, 0, 2800, 2800, -2000, depth);
    return (int64_t)needed;
}
