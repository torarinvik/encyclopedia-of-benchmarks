/* +++Date last modified: 05-Jul-1997 */

/*
**        A Pratt-Boyer-Moore string search, written by Jerry Coffin
**  sometime or other in 1991.  Removed from original program, and
**  (incorrectly) rewritten for separate, generic use in early 1992.
**  Corrected with help from Thad Smith, late March and early
**  April 1992...hopefully it's correct this time. Revised by Bob Stout.
**
**  This is hereby placed in the Public Domain by its author.
**
**  10/21/93 rdg  Fixed bug found by Jeff Dunlop
*/
/* Jerry Coffin's Pratt-Boyer-Moore helper; explicitly placed in the Public Domain by its author. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cbench_office_pratt_boyer_moore(const std::int64_t* values, std::size_t length) {
    if (values == nullptr || length < 3 || length > 321) return -2;
    const auto n_i = values[0], m_i = values[1];
    if (n_i < 0 || n_i > 255 || m_i < 1 || m_i > 64 ||
        length != 2 + static_cast<std::size_t>(n_i + m_i)) return -2;
    const auto n = static_cast<std::size_t>(n_i), m = static_cast<std::size_t>(m_i);
    const std::size_t text_start = 2, pattern_start = text_start + n;
    for (std::size_t i = text_start; i < length; ++i)
        if (values[i] < 1 || values[i] > 127) return -2;
    std::size_t table[128];
    for (auto& shift : table) shift = m;
    for (std::size_t i = 0; i < m; ++i)
        table[static_cast<std::size_t>(values[pattern_start + i])] = m - i - 1;
    std::size_t pos = m - 1;
    while (pos < n) {
        std::size_t shift = table[static_cast<std::size_t>(values[text_start + pos])];
        while (pos < n && shift > 0) {
            pos += shift;
            if (pos < n) shift = table[static_cast<std::size_t>(values[text_start + pos])];
        }
        if (pos < n && shift == 0) {
            const std::size_t start = pos - m + 1;
            std::size_t j = 0;
            while (j < m && values[pattern_start + j] == values[text_start + start + j]) ++j;
            if (j == m) return static_cast<std::int64_t>(start);
            ++pos;
        }
    }
    return -1;
}
