#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

static void search(unsigned columns, unsigned n, const std::uint64_t *rows,
                   unsigned covered, unsigned selected, std::vector<std::uint8_t>& out) {
    const unsigned full = (1u << columns) - 1u;
    if (covered == full) { out.push_back(static_cast<std::uint8_t>(selected)); return; }
    unsigned best = columns + 1, best_count = n + 1;
    for (unsigned col = 0; col < columns; ++col) {
        unsigned bit = 1u << col;
        if (covered & bit) continue;
        unsigned count = 0;
        for (unsigned row = 0; row < n; ++row) if ((rows[row] & bit) && !(rows[row] & covered)) ++count;
        if (!count) return;
        if (count < best_count) { best = col; best_count = count; }
    }
    unsigned bit = 1u << best;
    for (unsigned row = 0; row < n; ++row)
        if ((rows[row] & bit) && !(rows[row] & covered)) search(columns, n, rows, covered | rows[row], selected | (1u << row), out);
}

extern "C" std::int64_t dancing_links(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > 10) return -1;
    auto columns = input[0], n = input[1];
    if (columns < 1 || columns > 8 || n < 0 || n > 8 || length != static_cast<std::size_t>(n + 2)) return -1;
    const std::uint64_t full = (1u << columns) - 1u;
    std::uint64_t rows[8]{};
    for (int i = 0; i < n; ++i) { if (input[i+2] <= 0 || (static_cast<std::uint64_t>(input[i+2]) & ~full)) return -1; rows[i] = input[i+2]; }
    std::vector<std::uint8_t> solutions;
    search(columns, n, rows, 0, 0, solutions);
    std::sort(solutions.begin(), solutions.end());
    if (capacity < solutions.size() || (!solutions.empty() && !output)) return -2;
    std::copy(solutions.begin(), solutions.end(), output);
    return static_cast<std::int64_t>(solutions.size());
}
