#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 8;
std::int64_t count_from(int n, int column, std::array<bool, max_n>& rows,
                        std::array<bool, 2 * max_n>& down, std::array<bool, 2 * max_n>& up) {
    if (column == n) return 1;
    std::int64_t count = 0;
    for (int row = 0; row < n; ++row) {
        const int d = row - column + n - 1, u = row + column;
        if (!rows[row] && !down[d] && !up[u]) {
            rows[row] = down[d] = up[u] = true;
            count += count_from(n, column + 1, rows, down, up);
            rows[row] = down[d] = up[u] = false;
        }
    }
    return count;
}
}
extern "C" std::int64_t n_queens_solution_count(const std::int64_t* values, std::size_t length) noexcept {
    if (!values || length != 1 || values[0] < 0 || values[0] > max_n) return -1;
    std::array<bool, max_n> rows{};
    std::array<bool, 2 * max_n> down{}, up{};
    return count_from(static_cast<int>(values[0]), 0, rows, down, up);
}
