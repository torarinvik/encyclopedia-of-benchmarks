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
package cbench_office_pratt_boyer_moore
import "core:c"
// Jerry Coffin's Pratt-Boyer-Moore helper, explicitly placed in the Public Domain by its author.

cbench_office_pratt_boyer_moore :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 3 || length > 321 do return -2
    text_length, pattern_length := values[0], values[1]
    if text_length < 0 || text_length > 255 || pattern_length < 1 || pattern_length > 64 do return -2
    if length != c.size_t(2 + text_length + pattern_length) do return -2
    text_start := c.size_t(2)
    pattern_start := text_start + c.size_t(text_length)
    for i := text_start; i < length; i += 1 { if values[i] < 1 || values[i] > 127 do return -2 }
    shifts: [128]c.size_t
    for i := 0; i < 128; i += 1 { shifts[i] = c.size_t(pattern_length) }
    for i := c.size_t(0); i < c.size_t(pattern_length); i += 1 {
        shifts[c.size_t(values[pattern_start+i])] = c.size_t(pattern_length) - i - 1
    }
    pos := c.size_t(pattern_length) - 1
    for pos < c.size_t(text_length) {
        shift := shifts[c.size_t(values[text_start+pos])]
        for pos < c.size_t(text_length) && shift > 0 {
            pos += shift
            if pos < c.size_t(text_length) do shift = shifts[c.size_t(values[text_start+pos])]
        }
        if pos < c.size_t(text_length) && shift == 0 {
            start := pos - c.size_t(pattern_length) + 1
            j := c.size_t(0)
            for j < c.size_t(pattern_length) && values[pattern_start+j] == values[text_start+start+j] { j += 1 }
            if j == c.size_t(pattern_length) do return i64(start)
            pos += 1
        }
    }
    return -1
}
