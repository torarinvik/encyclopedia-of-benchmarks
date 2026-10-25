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
const MAX_INPUT: usize = 321;

pub export fn cbench_office_pratt_boyer_moore(values: ?[*]const i64, length: usize) i64 {
    const input = values orelse return -2;
    if (length < 3 or length > MAX_INPUT) return -2;
    const text_len_i = input[0];
    const pattern_len_i = input[1];
    if (text_len_i < 0 or text_len_i > 255 or pattern_len_i < 1 or pattern_len_i > 64) return -2;
    const n: usize = @intCast(text_len_i);
    const m: usize = @intCast(pattern_len_i);
    if (length != 2 + n + m) return -2;
    const text_start: usize = 2;
    const pattern_start = text_start + n;
    for (text_start..length) |i| if (input[i] < 1 or input[i] > 127) return -2;
    var shifts = [_]usize{m} ** 128;
    for (0..m) |i| shifts[@intCast(input[pattern_start + i])] = m - i - 1;
    var pos = m - 1;
    while (pos < n) {
        var shift = shifts[@intCast(input[text_start + pos])];
        while (pos < n and shift > 0) {
            pos += shift;
            if (pos < n) shift = shifts[@intCast(input[text_start + pos])];
        }
        if (pos < n and shift == 0) {
            const start = pos - m + 1;
            var j: usize = 0;
            while (j < m and input[pattern_start + j] == input[text_start + start + j]) : (j += 1) {}
            if (j == m) return @intCast(start);
            pos += 1;
        }
    }
    return -1;
}
