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
/*
** A Pratt-Boyer-Moore string search, written by Jerry Coffin
** sometime or other in 1991; source revised by Bob Stout.
** This algorithm is hereby placed in the Public Domain by its author.
*/
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 255
#define MAX_PATTERN 64
#define MAX_INPUT (2 + MAX_TEXT + MAX_PATTERN)

int64_t cbench_office_pratt_boyer_moore(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || length > MAX_INPUT) return -2;
    const int64_t text_length_i = values[0], pattern_length_i = values[1];
    if (text_length_i < 0 || text_length_i > MAX_TEXT ||
        pattern_length_i < 1 || pattern_length_i > MAX_PATTERN ||
        length != 2 + (size_t)text_length_i + (size_t)pattern_length_i) return -2;
    const size_t text_length = (size_t)text_length_i;
    const size_t pattern_length = (size_t)pattern_length_i;
    const size_t text_start = 2, pattern_start = text_start + text_length;
    for (size_t i = text_start; i < length; ++i)
        if (values[i] < 1 || values[i] > 127) return -2;

    size_t table[128];
    for (size_t i = 0; i < 128; ++i) table[i] = pattern_length;
    for (size_t i = 0; i < pattern_length; ++i)
        table[(size_t)values[pattern_start + i]] = pattern_length - i - 1;

    size_t pos = pattern_length - 1;
    while (pos < text_length) {
        size_t shift = table[(size_t)values[text_start + pos]];
        while (pos < text_length && shift > 0) {
            pos += shift;
            if (pos < text_length) shift = table[(size_t)values[text_start + pos]];
        }
        if (pos < text_length && shift == 0) {
            const size_t start = pos - pattern_length + 1;
            size_t j = 0;
            while (j < pattern_length &&
                   values[pattern_start + j] == values[text_start + start + j]) ++j;
            if (j == pattern_length) return (int64_t)start;
            ++pos;
        }
    }
    return -1;
}
