#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_rows = 16;
constexpr int max_columns = 16;

std::int64_t solve(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > 259) return -1;
    if (input[0] < 1 || input[0] > max_rows || input[1] < 1 || input[1] > max_columns) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    if (length != 2 + rows * columns) return -1;
    for (std::size_t index = 2; index < length; ++index)
        if (input[index] != 0 && input[index] != 1) return -1;

    std::array<std::int64_t, max_columns> last_one{};
    std::array<int, max_columns> left{}, right{}, stack{};
    last_one.fill(-1);
    std::int64_t best = 0;
    for (std::size_t row = 0; row < rows; ++row) {
        for (std::size_t column = 0; column < columns; ++column)
            if (input[2 + row * columns + column] == 1) last_one[column] = static_cast<std::int64_t>(row);

        std::size_t top = 0;
        for (std::size_t column = 0; column < columns; ++column) {
            while (top > 0 && last_one[static_cast<std::size_t>(stack[top - 1])] <= last_one[column]) --top;
            left[column] = top == 0 ? -1 : stack[top - 1];
            stack[top++] = static_cast<int>(column);
        }
        top = 0;
        for (std::size_t cursor = columns; cursor > 0; --cursor) {
            const auto column = cursor - 1;
            while (top > 0 && last_one[static_cast<std::size_t>(stack[top - 1])] <= last_one[column]) --top;
            right[column] = top == 0 ? static_cast<int>(columns) : stack[top - 1];
            stack[top++] = static_cast<int>(column);
        }
        for (std::size_t column = 0; column < columns; ++column) {
            const auto height = static_cast<std::int64_t>(row) - last_one[column];
            const auto width = right[column] - left[column] - 1;
            const auto area = height * width;
            if (area > best) best = area;
        }
    }
    return best;
}
}

extern "C" std::int64_t largest_zero_submatrix(const std::int64_t* input,
        std::size_t length) noexcept {
    return solve(input, length);
}
