#include <cstddef>
#include <cstdint>

namespace {
std::int64_t search_row(const std::int64_t* matrix, std::int64_t row_base,
                        std::int64_t low, std::int64_t high, std::int64_t target) {
    while (low <= high) {
        const auto middle = low + (high - low) / 2;
        const auto value = matrix[row_base + middle];
        if (value == target) return middle;
        if (value < target) low = middle + 1;
        else high = middle - 1;
    }
    return -1;
}
}

extern "C" std::int64_t binary_search2d_array(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 3) return -1;
    const auto rows = values[0], cols = values[1], target = values[2];
    if (rows < 2 || rows > 32 || cols < 3 || cols > 32) return -1;
    if (length != 3 + static_cast<std::size_t>(rows * cols)) return -1;
    const auto* matrix = values + 3;
    const auto middle_col = cols / 2;
    std::int64_t start_row = 0, end_row = rows - 1;
    while (start_row < end_row - 1) {
        const auto middle_row = start_row + (end_row - start_row) / 2;
        const auto value = matrix[middle_row * cols + middle_col];
        if (value == target) return middle_row * cols + middle_col;
        if (value < target) start_row = middle_row;
        else end_row = middle_row;
    }
    if (matrix[start_row * cols + middle_col] == target) return start_row * cols + middle_col;
    if (matrix[end_row * cols + middle_col] == target) return end_row * cols + middle_col;
    if (target <= matrix[start_row * cols + middle_col - 1]) {
        const auto col = search_row(matrix, start_row * cols, 0, middle_col - 1, target);
        return col < 0 ? -1 : start_row * cols + col;
    }
    if (target >= matrix[start_row * cols + middle_col + 1] && target <= matrix[start_row * cols + cols - 1]) {
        const auto col = search_row(matrix, start_row * cols, middle_col + 1, cols - 1, target);
        return col < 0 ? -1 : start_row * cols + col;
    }
    if (target <= matrix[end_row * cols + middle_col - 1]) {
        const auto col = search_row(matrix, end_row * cols, 0, middle_col - 1, target);
        return col < 0 ? -1 : end_row * cols + col;
    }
    const auto col = search_row(matrix, end_row * cols, middle_col + 1, cols - 1, target);
    return col < 0 ? -1 : end_row * cols + col;
}
