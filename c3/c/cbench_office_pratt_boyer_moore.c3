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
module cbench_office_pratt_boyer_moore;
/* Jerry Coffin's Pratt-Boyer-Moore helper; explicitly placed in the Public Domain by its author. */
const long MAX_TEXT = 255;
const long MAX_PATTERN = 64;

fn long cbench_office_pratt_boyer_moore(long* values, usz length) @export("cbench_office_pratt_boyer_moore") {
    if (values == null || length < 3 || length > 321) return -2;
    long text_len = values[0], pattern_len = values[1];
    if (text_len < 0 || text_len > MAX_TEXT || pattern_len < 1 || pattern_len > MAX_PATTERN ||
        length != (usz)(2 + text_len + pattern_len)) return -2;
    usz n = (usz)text_len, m = (usz)pattern_len;
    usz text_start = 2, pattern_start = text_start + n;
    for (usz i = text_start; i < length; i++) if (values[i] < 1 || values[i] > 127) return -2;
    usz[128] table;
    for (usz i = 0; i < 128; i++) table[i] = m;
    for (usz i = 0; i < m; i++) table[(usz)values[pattern_start + i]] = m - i - 1;
    usz pos = m - 1;
    while (pos < n) {
        usz shift = table[(usz)values[text_start + pos]];
        while (pos < n && shift > 0) {
            pos += shift;
            if (pos < n) shift = table[(usz)values[text_start + pos]];
        }
        if (pos < n && shift == 0) {
            usz start = pos - m + 1, j = 0;
            while (j < m && values[pattern_start + j] == values[text_start + start + j]) j++;
            if (j == m) return (long)start;
            pos++;
        }
    }
    return -1;
}
