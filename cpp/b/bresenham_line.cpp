#include <algorithm>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t coordinate_limit = 1'000'000;
constexpr std::int64_t step_limit = 4096;

void write_i32_le(std::uint8_t* output, std::size_t offset, std::int32_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t bresenham_line(const std::int64_t* values, std::size_t length,
                                        std::uint8_t* output,
                                        std::size_t output_capacity) noexcept {
    if (length != 4 || values == nullptr) return -1;
    for (std::size_t index = 0; index < 4; ++index)
        if (values[index] < -coordinate_limit || values[index] > coordinate_limit) return -1;

    const std::int64_t x0 = values[0], y0 = values[1], x1 = values[2], y1 = values[3];
    const std::int64_t dx = x0 < x1 ? x1 - x0 : x0 - x1;
    const std::int64_t dy = y0 < y1 ? y1 - y0 : y0 - y1;
    const std::int64_t major_steps = std::max(dx, dy);
    if (major_steps > step_limit) return -1;
    const std::size_t required = static_cast<std::size_t>(major_steps + 1) * 8;
    if (output == nullptr || output_capacity < required) return -2;

    const std::int64_t sx = x0 < x1 ? 1 : -1;
    const std::int64_t sy = y0 < y1 ? 1 : -1;
    std::int64_t x = x0, y = y0, err = dx - dy;
    std::size_t position = 0;
    while (true) {
        write_i32_le(output, position, static_cast<std::int32_t>(x));
        write_i32_le(output, position + 4, static_cast<std::int32_t>(y));
        position += 8;
        if (x == x1 && y == y1) break;
        const std::int64_t e2 = 2 * err;
        if (e2 > -dy) { err -= dy; x += sx; }
        if (e2 < dx) { err += dx; y += sy; }
    }
    return static_cast<std::int64_t>(position);
}
