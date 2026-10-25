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
use std::slice;

#[no_mangle]
pub unsafe extern "C" fn cbench_office_pratt_boyer_moore(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 3 || length > 321 { return -2; }
    let input = slice::from_raw_parts(values, length);
    let (text_len_i, pattern_len_i) = (input[0], input[1]);
    if !(0..=255).contains(&text_len_i) || !(1..=64).contains(&pattern_len_i) ||
        length != 2 + text_len_i as usize + pattern_len_i as usize { return -2; }
    let n = text_len_i as usize;
    let m = pattern_len_i as usize;
    let text_start = 2;
    let pattern_start = text_start + n;
    if input[text_start..].iter().any(|&byte| !(1..=127).contains(&byte)) { return -2; }
    let mut shifts = [m; 128];
    for i in 0..m { shifts[input[pattern_start + i] as usize] = m - i - 1; }
    let mut pos = m - 1;
    while pos < n {
        let mut shift = shifts[input[text_start + pos] as usize];
        while pos < n && shift > 0 {
            pos += shift;
            if pos < n { shift = shifts[input[text_start + pos] as usize]; }
        }
        if pos < n && shift == 0 {
            let start = pos - m + 1;
            if input[pattern_start..pattern_start + m] == input[text_start + start..text_start + start + m] {
                return start as i64;
            }
            pos += 1;
        }
    }
    -1
}
