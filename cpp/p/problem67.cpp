#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_ROWS = 100;
constexpr std::size_t MAX_VALUES = MAX_ROWS * (MAX_ROWS + 1) / 2;
constexpr std::int64_t VALUE_LIMIT = 1'000'000;
}

extern "C" std::int64_t problem67(const std::int64_t *input, std::size_t length)
{
    if (input == nullptr || length < 2 || length > MAX_VALUES + 1) return -1;
    const std::int64_t rows = input[0];
    if (rows < 1 || rows > static_cast<std::int64_t>(MAX_ROWS) ||
        length != static_cast<std::size_t>(rows * (rows + 1) / 2) + 1) return -1;
    std::int64_t best[MAX_VALUES] = {};
    const std::size_t value_count = length - 1;
    for (std::size_t index = 0; index < value_count; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < 0 || value > VALUE_LIMIT) return -1;
        best[index] = value;
    }
    for (std::int64_t row = rows - 1; row > 0; --row) {
        const std::size_t parent_start = static_cast<std::size_t>((row - 1) * row / 2);
        const std::size_t child_start = static_cast<std::size_t>(row * (row + 1) / 2);
        for (std::int64_t column = 0; column < row; ++column) {
            const std::size_t parent = parent_start + static_cast<std::size_t>(column);
            const std::size_t child = child_start + static_cast<std::size_t>(column);
            const std::int64_t left = best[child];
            const std::int64_t right = best[child + 1];
            best[parent] += left > right ? left : right;
        }
    }
    return best[0];
}
