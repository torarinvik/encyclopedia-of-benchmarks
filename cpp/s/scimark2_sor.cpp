#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxRows = 8;
constexpr int kMaxCols = 8;
constexpr std::size_t kMaxInput = 3 + kMaxRows * kMaxCols;
}

extern "C" std::int64_t scimark2_sor(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    if (input[0] < 2 || input[0] > kMaxRows || input[1] < 2 || input[1] > kMaxCols ||
        input[2] < 0 || input[2] > 8) return -1;
    const int rows = static_cast<int>(input[0]);
    const int cols = static_cast<int>(input[1]);
    const int iterations = static_cast<int>(input[2]);
    if (length != 3 + static_cast<std::size_t>(rows) * static_cast<std::size_t>(cols)) return -1;
    std::int64_t grid[kMaxRows * kMaxCols];
    for (int i = 0; i < rows * cols; ++i) {
        const std::int64_t value = input[3 + static_cast<std::size_t>(i)];
        if (value < -1000 || value > 1000) return -1;
        grid[i] = value;
    }
    for (int pass = 0; pass < iterations; ++pass) {
        for (int row = 1; row < rows - 1; ++row) {
            for (int col = 1; col < cols - 1; ++col) {
                const int index = row * cols + col;
                const std::int64_t neighbors = grid[index - cols] + grid[index + cols] + grid[index - 1] + grid[index + 1];
                const std::int64_t numerator = 1250 * neighbors - 1000 * grid[index];
                grid[index] = numerator / 4000;
            }
        }
    }
    std::int64_t checksum = 0;
    for (int i = 0; i < rows * cols; ++i) checksum += static_cast<std::int64_t>(i + 1) * grid[i];
    return checksum;
}
