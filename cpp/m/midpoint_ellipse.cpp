// Midpoint ellipse rasterization preserving Java's point order and duplicates.
#include <cstddef>
#include <cstdint>

namespace {
void write_i32_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[position + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}

template <typename Emit>
void visit_points(std::int64_t center_x, std::int64_t center_y,
                  std::int64_t a, std::int64_t b, Emit emit) {
    if (a == 0 && b == 0) { emit(center_x, center_y); return; }
    if (a == 0) {
        for (std::int64_t y = center_y - b; y <= center_y + b; ++y) emit(center_x, y);
        return;
    }
    if (b == 0) {
        for (std::int64_t x = center_x - a; x <= center_x + a; ++x) emit(x, center_y);
        return;
    }

    std::int64_t x = 0, y = b;
    double d1 = static_cast<double>(b * b - a * a * b) + 0.25 * static_cast<double>(a * a);
    double dx = 2.0 * b * b * x;
    double dy = 2.0 * a * a * y;
    while (dx < dy) {
        emit(center_x + x, center_y + y); emit(center_x - x, center_y + y);
        emit(center_x + x, center_y - y); emit(center_x - x, center_y - y);
        if (d1 < 0) {
            ++x; dx += 2 * b * b; d1 += dx + b * b;
        } else {
            ++x; --y; dx += 2 * b * b; dy -= 2 * a * a; d1 += dx - dy + b * b;
        }
    }
    double d2 = b * b * (x + 0.5) * (x + 0.5) + a * a * (y - 1) * (y - 1) - a * a * b * b;
    while (y >= 0) {
        emit(center_x + x, center_y + y); emit(center_x - x, center_y + y);
        emit(center_x + x, center_y - y); emit(center_x - x, center_y - y);
        if (d2 > 0) {
            --y; dy -= 2 * a * a; d2 += a * a - dy;
        } else {
            --y; ++x; dx += 2 * b * b; dy -= 2 * a * a; d2 += dx - dy + a * a;
        }
    }
}
}

extern "C" std::int64_t midpoint_ellipse(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 4 || input[0] < -10000 || input[0] > 10000 ||
        input[1] < -10000 || input[1] > 10000 || input[2] < 0 || input[2] > 100 ||
        input[3] < 0 || input[3] > 100) return -1;
    std::size_t count = 0;
    visit_points(input[0], input[1], input[2], input[3], [&](std::int64_t, std::int64_t) { ++count; });
    if (output == nullptr || output_capacity < count * 8) return -2;
    std::size_t position = 0;
    visit_points(input[0], input[1], input[2], input[3], [&](std::int64_t x, std::int64_t y) {
        write_i32_le(output, position, x); write_i32_le(output, position + 4, y); position += 8;
    });
    return static_cast<std::int64_t>(count);
}
