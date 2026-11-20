#include <stddef.h>
#include <stdint.h>

enum { MAX_TEXT = 256, MIN_PATTERN = 1, MAX_PATTERN = 16, MAX_INPUT = 274 };

int64_t optimal_mismatch(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_INPUT) return -2;
    if (values[0] < 0 || values[0] > MAX_TEXT ||
        values[1] < MIN_PATTERN || values[1] > MAX_PATTERN) return -2;
    const size_t n = (size_t)values[0];
    const size_t m = (size_t)values[1];
    if (length != 2 + n + m) return -2;
    const size_t pattern_start = 2 + n;
    for (size_t i = 0; i < n + m; ++i)
        if (values[2 + i] < 0 || values[2 + i] > 127) return -2;
    if (m > n) return -1;

    size_t frequency[128] = {0};
    for (size_t i = 0; i < n; ++i) ++frequency[(size_t)values[2 + i]];
    size_t order[MAX_PATTERN];
    for (size_t i = 0; i < m; ++i) order[i] = i;
    for (size_t i = 1; i < m; ++i) {
        const size_t selected = order[i];
        size_t cursor = i;
        while (cursor > 0) {
            const size_t previous = order[cursor - 1];
            const size_t previous_frequency = frequency[(size_t)values[pattern_start + previous]];
            const size_t selected_frequency = frequency[(size_t)values[pattern_start + selected]];
            if (previous_frequency < selected_frequency ||
                (previous_frequency == selected_frequency && previous > selected)) break;
            order[cursor] = previous;
            --cursor;
        }
        order[cursor] = selected;
    }

    size_t quick_shift[128];
    for (size_t byte = 0; byte < 128; ++byte) quick_shift[byte] = m + 1;
    for (size_t i = 0; i < m; ++i)
        quick_shift[(size_t)values[pattern_start + i]] = m - i;

    size_t adapted_shift[MAX_PATTERN];
    for (size_t rank = 0; rank < m; ++rank) {
        adapted_shift[rank] = m;
        const size_t mismatch = order[rank];
        for (size_t shift = 1; shift <= m; ++shift) {
            int compatible = 1;
            for (size_t prior = 0; prior < rank; ++prior) {
                const size_t position = order[prior];
                if (position >= shift &&
                    values[pattern_start + position] != values[pattern_start + position - shift]) {
                    compatible = 0;
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

    size_t start = 0;
    const size_t last_start = n - m;
    while (start <= last_start) {
        size_t rank = 0;
        while (rank < m &&
               values[2 + start + order[rank]] == values[pattern_start + order[rank]]) ++rank;
        if (rank == m) return (int64_t)start;
        if (start + m == n) break;
        const size_t quick = quick_shift[(size_t)values[2 + start + m]];
        start += adapted_shift[rank] > quick ? adapted_shift[rank] : quick;
    }
    return -1;
}
