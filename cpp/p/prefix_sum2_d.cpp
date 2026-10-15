/* Build a padded two-dimensional prefix table and answer one inclusive rectangle. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t invalid_result = INT64_MIN;
constexpr std::size_t max_dimension = 16;
}

extern "C" std::int64_t prefix_sum2_d(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 7) return invalid_result;
    const auto raw_rows = input[0], raw_cols = input[1];
    if (raw_rows < 1 || raw_rows > static_cast<std::int64_t>(max_dimension) ||
        raw_cols < 1 || raw_cols > static_cast<std::int64_t>(max_dimension)) return invalid_result;
    const auto rows = static_cast<std::size_t>(raw_rows), cols = static_cast<std::size_t>(raw_cols);
    if (length != 2 + rows * cols + 4) return invalid_result;
    const auto query = 2 + rows * cols;
    const auto row1v = input[query], col1v = input[query + 1];
    const auto row2v = input[query + 2], col2v = input[query + 3];
    if (row1v < 0 || col1v < 0 || row2v < row1v || col2v < col1v ||
        static_cast<std::uint64_t>(row2v) >= rows || static_cast<std::uint64_t>(col2v) >= cols) return invalid_result;
    std::int64_t prefix[max_dimension + 1][max_dimension + 1]{};
    for (std::size_t i = 0; i < rows; ++i) {
        for (std::size_t j = 0; j < cols; ++j) {
            const auto value = input[2 + i * cols + j];
            if (value < -1000 || value > 1000) return invalid_result;
            prefix[i + 1][j + 1] = value + prefix[i][j + 1] + prefix[i + 1][j] - prefix[i][j];
        }
    }
    const auto row1 = static_cast<std::size_t>(row1v), col1 = static_cast<std::size_t>(col1v);
    const auto row2 = static_cast<std::size_t>(row2v), col2 = static_cast<std::size_t>(col2v);
    return prefix[row2 + 1][col2 + 1] - prefix[row1][col2 + 1] -
           prefix[row2 + 1][col1] + prefix[row1][col1];
}
