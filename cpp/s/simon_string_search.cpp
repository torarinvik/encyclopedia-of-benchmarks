#include <cstddef>
#include <cstdint>

extern "C" std::int64_t simon_string_search(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > 274) return -2;
    if (values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16) return -2;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    const std::size_t m = static_cast<std::size_t>(values[1]);
    if (length != 2 + n + m) return -2;
    for (std::size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 15) return -2;
    const std::size_t p = 2 + n;
    int head[16], edge_target[16], edge_next[16];
    for (int i = 0; i < 16; ++i) head[i] = -1;
    int edge_count = 0, ell = -1;
    for (std::size_t i = 1; i < m; ++i) {
        const int k = ell;
        int cell = k < 0 ? -1 : head[k];
        ell = -1;
        if (values[p + i] == values[p + static_cast<std::size_t>(k + 1)]) ell = k + 1;
        else {
            edge_target[edge_count] = k + 1;
            edge_next[edge_count] = head[i - 1];
            head[i - 1] = edge_count++;
        }
        while (cell >= 0) {
            const int q = edge_target[cell];
            if (values[p + i] == values[p + static_cast<std::size_t>(q)]) ell = q;
            else {
                edge_target[edge_count] = q;
                edge_next[edge_count] = head[i - 1];
                head[i - 1] = edge_count++;
            }
            cell = edge_next[cell];
        }
    }
    int state = -1;
    std::int64_t matches = 0;
    for (std::size_t j = 0; j < n; ++j) {
        const std::int64_t symbol = values[2 + j];
        if (state < static_cast<int>(m) - 1 &&
            values[p + static_cast<std::size_t>(state + 1)] == symbol) {
            ++state;
        } else if (state >= 0) {
            int edge = head[state];
            state = -1;
            while (edge >= 0) {
                const int q = edge_target[edge];
                if (values[p + static_cast<std::size_t>(q)] == symbol) { state = q; break; }
                edge = edge_next[edge];
            }
        } else state = -1;
        if (state >= static_cast<int>(m) - 1) { ++matches; state = ell; }
    }
    return matches;
}
