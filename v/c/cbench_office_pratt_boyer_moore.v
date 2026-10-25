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
module cbench_office_pratt_boyer_moore
// Jerry Coffin's Pratt-Boyer-Moore helper, explicitly placed in the Public Domain by its author.

@[export: 'cbench_office_pratt_boyer_moore']
pub fn cbench_office_pratt_boyer_moore(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length < 3 || length > 321 { return -2 }
        text_length := values[0]
        pattern_length := values[1]
        if text_length < 0 || text_length > 255 || pattern_length < 1 || pattern_length > 64 { return -2 }
        if length != usize(2 + text_length + pattern_length) { return -2 }
        text_start := usize(2)
        pattern_start := text_start + usize(text_length)
        for i in text_start .. length { if values[i] < 1 || values[i] > 127 { return -2 } }
        mut shifts := [128]usize{}
        for i in 0 .. 128 { shifts[i] = usize(pattern_length) }
        for i in 0 .. usize(pattern_length) {
            shifts[usize(values[pattern_start + i])] = usize(pattern_length) - i - 1
        }
        mut pos := usize(pattern_length) - 1
        for pos < usize(text_length) {
            mut shift := shifts[usize(values[text_start + pos])]
            for pos < usize(text_length) && shift > 0 {
                pos += shift
                if pos < usize(text_length) { shift = shifts[usize(values[text_start + pos])] }
            }
            if pos < usize(text_length) && shift == 0 {
                start := pos - usize(pattern_length) + 1
                mut j := usize(0)
                for j < usize(pattern_length) && values[pattern_start + j] == values[text_start + start + j] { j++ }
                if j == usize(pattern_length) { return i64(start) }
                pos++
            }
        }
        return -1
    }
}
