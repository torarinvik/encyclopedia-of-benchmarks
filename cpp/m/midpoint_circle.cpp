// Midpoint circle rasterization with the source's eight-point emission order.
#include <cstddef>
#include <cstdint>

namespace {
void write_i32_le(std::uint8_t *output, std::size_t position, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint32_t>(value);
    output[position] = static_cast<std::uint8_t>(bits);
    output[position + 1] = static_cast<std::uint8_t>(bits >> 8);
    output[position + 2] = static_cast<std::uint8_t>(bits >> 16);
    output[position + 3] = static_cast<std::uint8_t>(bits >> 24);
}

std::size_t count_points(std::int64_t radius) noexcept {
    if (radius == 0) return 1;
    std::int64_t x = radius, y = 0, decision = 1 - radius;
    std::size_t count = 8;
    while (x > y) {
        ++y;
        if (decision <= 0) decision += 2 * y + 1;
        else {
            --x;
            decision += 2 * y - 2 * x + 1;
        }
        count += 8;
    }
    return count;
}

void write_symmetric(std::uint8_t *output, std::size_t &position,
                     std::int64_t center_x, std::int64_t center_y,
                     std::int64_t x, std::int64_t y) noexcept {
    const std::int64_t xs[8] = {x, -x, x, -x, y, -y, y, -y};
    const std::int64_t ys[8] = {y, y, -y, -y, x, x, -x, -x};
    for (std::size_t index = 0; index < 8; ++index) {
        write_i32_le(output, position, center_x + xs[index]);
        write_i32_le(output, position + 4, center_y + ys[index]);
        position += 8;
    }
}
}

extern "C" std::int64_t midpoint_circle(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output,
                                          std::size_t output_capacity) noexcept {
    if (input == nullptr || length != 3 || input[0] < -10000 || input[0] > 10000 ||
        input[1] < -10000 || input[1] > 10000 || input[2] < 0 || input[2] > 1000) return -1;

    const auto center_x = input[0], center_y = input[1], radius = input[2];
    const auto count = count_points(radius);
    const auto required = count * 8;
    if (output == nullptr || output_capacity < required) return -2;
    if (radius == 0) {
        write_i32_le(output, 0, center_x);
        write_i32_le(output, 4, center_y);
        return 1;
    }

    std::size_t position = 0;
    std::int64_t x = radius, y = 0, decision = 1 - radius;
    write_symmetric(output, position, center_x, center_y, x, y);
    while (x > y) {
        ++y;
        if (decision <= 0) decision += 2 * y + 1;
        else {
            --x;
            decision += 2 * y - 2 * x + 1;
        }
        write_symmetric(output, position, center_x, center_y, x, y);
    }
    return static_cast<std::int64_t>(count);
}
