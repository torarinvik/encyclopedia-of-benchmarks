#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_side = 32;
constexpr std::size_t max_cells = max_side * max_side;

void put_i64(std::uint8_t *output, std::size_t index, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t flood_fill(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 6 || length > 6 + max_cells) return -1;
    const auto width_value = input[0], height_value = input[1];
    const auto start_x_value = input[2], start_y_value = input[3];
    const auto new_color = input[4], target_color = input[5];
    if (width_value < 1 || width_value > static_cast<std::int64_t>(max_side)
        || height_value < 1 || height_value > static_cast<std::int64_t>(max_side)
        || new_color < INT32_MIN || new_color > INT32_MAX
        || target_color < INT32_MIN || target_color > INT32_MAX || new_color == target_color) return -1;
    const auto width = static_cast<std::size_t>(width_value);
    const auto height = static_cast<std::size_t>(height_value);
    if (length != 6 + width * height || start_x_value < 0 || start_x_value >= width_value
        || start_y_value < 0 || start_y_value >= height_value) return -1;
    std::int64_t image[max_cells];
    const auto cells = width * height;
    for (std::size_t index = 0; index < cells; ++index) {
        image[index] = input[6 + index];
        if (image[index] < INT32_MIN || image[index] > INT32_MAX) return -1;
    }
    const auto start = static_cast<std::size_t>(start_x_value) * height + static_cast<std::size_t>(start_y_value);
    if (image[start] == target_color) {
        std::size_t stack[max_cells], top = 0;
        image[start] = new_color;
        stack[top++] = start;
        while (top != 0) {
            const auto index = stack[--top];
            const auto x = static_cast<std::int64_t>(index / height);
            const auto y = static_cast<std::int64_t>(index % height);
            for (int dx = -1; dx <= 1; ++dx) {
                for (int dy = -1; dy <= 1; ++dy) {
                    if (dx == 0 && dy == 0) continue;
                    const auto next_x = x + dx, next_y = y + dy;
                    if (next_x < 0 || next_x >= width_value || next_y < 0 || next_y >= height_value) continue;
                    const auto next = static_cast<std::size_t>(next_x) * height + static_cast<std::size_t>(next_y);
                    if (image[next] == target_color) {
                        image[next] = new_color;
                        stack[top++] = next;
                    }
                }
            }
        }
    }
    const auto required = cells * 8;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < cells; ++index) put_i64(output, index, image[index]);
    return static_cast<std::int64_t>(required);
}
