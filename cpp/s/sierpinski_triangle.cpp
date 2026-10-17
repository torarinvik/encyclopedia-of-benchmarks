#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_output_bytes = 11616;

void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
}

void emit_segment(std::uint8_t *output, std::size_t &position,
                  std::int64_t x0, std::int64_t y0, std::int64_t x1, std::int64_t y1) {
    write_i64_le(output, position, x0); position += 8;
    write_i64_le(output, position, y0); position += 8;
    write_i64_le(output, position, x1); position += 8;
    write_i64_le(output, position, y1); position += 8;
}

void draw_triangle(std::uint8_t *output, std::size_t &position,
                   std::int64_t x1, std::int64_t y1, std::int64_t x2, std::int64_t y2,
                   std::int64_t x3, std::int64_t y3, std::int64_t depth) {
    emit_segment(output, position, x1, y1, x2, y2);
    emit_segment(output, position, x2, y2, x3, y3);
    emit_segment(output, position, x3, y3, x1, y1);
    if (depth == 0) return;
    const auto abx = (x1 + x2) / 2, aby = (y1 + y2) / 2;
    const auto acx = (x1 + x3) / 2, acy = (y1 + y3) / 2;
    const auto bcx = (x2 + x3) / 2, bcy = (y2 + y3) / 2;
    draw_triangle(output, position, x1, y1, abx, aby, acx, acy, depth - 1);
    draw_triangle(output, position, x2, y2, abx, aby, bcx, bcy, depth - 1);
    draw_triangle(output, position, x3, y3, bcx, bcy, acx, acy, depth - 1);
}
}

extern "C" std::int64_t sierpinski_triangle(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 1) return -1;
    const auto depth = input[0];
    if (depth < 0 || depth > 4) return -1;
    std::size_t calls = 1;
    for (std::int64_t level = 0; level < depth; ++level) calls = calls * 3 + 1;
    const std::size_t needed = calls * 96;
    if (needed > max_output_bytes) return -1;
    if (output == nullptr || capacity < needed) return -2;
    std::size_t position = 0;
    draw_triangle(output, position, -2800, -2000, 0, 2800, 2800, -2000, depth);
    return static_cast<std::int64_t>(needed);
}
