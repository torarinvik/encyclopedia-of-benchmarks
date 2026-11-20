#include <cstddef>
#include <cstdint>

extern "C" std::int64_t optimal_mismatch(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 2 || length > 274) return -2;
    if (values[0] < 0 || values[0] > 256 || values[1] < 1 || values[1] > 16) return -2;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    const std::size_t m = static_cast<std::size_t>(values[1]);
    if (length != 2 + n + m) return -2;
    const std::size_t pattern_start = 2 + n;
    for (std::size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 127) return -2;
    if (m > n) return -1;

    std::size_t frequency[128]{};
    for (std::size_t i = 0; i < n; ++i) ++frequency[static_cast<std::size_t>(values[2 + i])];
    std::size_t order[16]{};
    for (std::size_t i = 0; i < m; ++i) order[i] = i;
    for (std::size_t i = 1; i < m; ++i) {
        const std::size_t selected = order[i];
        std::size_t cursor = i;
        while (cursor > 0) {
            const std::size_t previous = order[cursor - 1];
            const auto pf = frequency[static_cast<std::size_t>(values[pattern_start + previous])];
            const auto sf = frequency[static_cast<std::size_t>(values[pattern_start + selected])];
            if (pf < sf || (pf == sf && previous > selected)) break;
            order[cursor] = previous;
            --cursor;
        }
        order[cursor] = selected;
    }

    std::size_t quick_shift[128];
    for (std::size_t byte = 0; byte < 128; ++byte) quick_shift[byte] = m + 1;
    for (std::size_t i = 0; i < m; ++i)
        quick_shift[static_cast<std::size_t>(values[pattern_start + i])] = m - i;

    std::size_t adapted_shift[16]{};
    for (std::size_t rank = 0; rank < m; ++rank) {
        adapted_shift[rank] = m;
        const std::size_t mismatch = order[rank];
        for (std::size_t shift = 1; shift <= m; ++shift) {
            bool compatible = true;
            for (std::size_t prior = 0; prior < rank; ++prior) {
                const std::size_t position = order[prior];
                if (position >= shift &&
                    values[pattern_start + position] != values[pattern_start + position - shift]) {
                    compatible = false;
                    break;
                }
            }
            if (!compatible) continue;
            if (mismatch >= shift &&
                values[pattern_start + mismatch - shift] == values[pattern_start + mismatch]) continue;
            adapted_shift[rank] = shift;
            break;
        }
    }

    std::size_t start = 0;
    const std::size_t last_start = n - m;
    while (start <= last_start) {
        std::size_t rank = 0;
        while (rank < m &&
               values[2 + start + order[rank]] == values[pattern_start + order[rank]]) ++rank;
        if (rank == m) return static_cast<std::int64_t>(start);
        if (start + m == n) break;
        const std::size_t quick = quick_shift[static_cast<std::size_t>(values[2 + start + m])];
        start += adapted_shift[rank] > quick ? adapted_shift[rank] : quick;
    }
    return -1;
}
