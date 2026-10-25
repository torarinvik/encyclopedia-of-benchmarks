/* Rodinia pathfinder bounded grid dynamic-programming core. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t rodinia_pathfinder(const std::int64_t *input, std::size_t length) noexcept {
    constexpr std::size_t max_rows = 32, max_cols = 32, max_cells = max_rows * max_cols;
    if (input == nullptr || length < 4 || length > 3 + max_cells) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(max_cols) ||
        input[1] < 1 || input[1] > static_cast<std::int64_t>(max_rows) ||
        input[2] < 1 || input[2] > 4) return -1;
    const auto cols = static_cast<std::size_t>(input[0]);
    const auto rows = static_cast<std::size_t>(input[1]);
    const auto height = static_cast<std::size_t>(input[2]);
    const auto cells = cols * rows;
    if (length != 3 + cells) return -1;
    for (std::size_t i = 0; i < cells; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 9) return -1;

    std::int64_t previous[max_cols]{}, current[max_cols]{};
    for (std::size_t col = 0; col < cols; ++col) previous[col] = input[3 + col];
    for (std::size_t first = 1; first < rows; first += height) {
        const auto steps = (rows - first < height) ? rows - first : height;
        for (std::size_t step = 0; step < steps; ++step) {
            const auto row = first + step;
            for (std::size_t col = 0; col < cols; ++col) {
                auto best = previous[col];
                if (col > 0 && previous[col - 1] < best) best = previous[col - 1];
                if (col + 1 < cols && previous[col + 1] < best) best = previous[col + 1];
                current[col] = best + input[3 + row * cols + col];
            }
            for (std::size_t col = 0; col < cols; ++col) previous[col] = current[col];
        }
    }
    auto answer = previous[0];
    for (std::size_t col = 1; col < cols; ++col)
        if (previous[col] < answer) answer = previous[col];
    return answer;
}
