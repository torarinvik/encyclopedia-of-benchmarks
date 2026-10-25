/* Part of the Bison parser generator,
   Copyright (C) 1984 Bob Corbett and Free Software Foundation, Inc.

BISON is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY.  No author or distributor accepts responsibility to anyone
for the consequences of using it or for whether it serves any
particular purpose or works at all, unless he says so in writing.
Refer to the BISON General Public License for full details.

Everyone is granted permission to copy, modify and redistribute BISON,
but only under the conditions described in the BISON General Public
License.  A copy of this license is supposed to have been given to you
along with BISON so you can know your rights and responsibilities.  It
should be in a file named COPYING.  Among other things, the copyright
notice and this notice must be preserved on all copies.

 In other words, you are welcome to use, share and improve this program.
 You are forbidden to forbid anyone else to use, share and improve
 what you give them.   Help stamp out software-hoarding!  */

/* Modified 2026: bounded numeric grammar adapter; no upstream code is copied. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_NONTERMINALS = 16, MAX_TERMINALS = 16, MAX_RULES = 32,
       MAX_RHS = 8, MAX_RHS_ITEMS = MAX_RULES * MAX_RHS,
       MAX_INPUT_LENGTH = 3 + MAX_RULES * (2 + MAX_RHS) };

int64_t prolangs_c_bison_nullable(const int64_t *input, size_t length)
{
    if (input == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_NONTERMINALS ||
        input[1] < 0 || input[1] > MAX_TERMINALS ||
        input[2] < 1 || input[2] > MAX_RULES) return -1;

    const int nonterminal_count = (int)input[0];
    const int terminal_count = (int)input[1];
    const int rule_count = (int)input[2];
    int lhs[MAX_RULES] = {0};
    int rhs_start[MAX_RULES] = {0};
    int rhs_length[MAX_RULES] = {0};
    int rhs[MAX_RHS_ITEMS] = {0};
    int remaining[MAX_RULES] = {0};
    int eligible[MAX_RULES] = {0};
    int nullable[MAX_NONTERMINALS] = {0};
    int queue[MAX_NONTERMINALS] = {0};
    int rhs_items = 0;
    size_t offset = 3;

    for (int rule = 0; rule < rule_count; ++rule) {
        if (offset + 2 > length) return -1;
        if (input[offset] < 0 || input[offset] >= nonterminal_count ||
            input[offset + 1] < 0 || input[offset + 1] > MAX_RHS) return -1;
        lhs[rule] = (int)input[offset++];
        rhs_length[rule] = (int)input[offset++];
        rhs_start[rule] = rhs_items;
        if (offset + (size_t)rhs_length[rule] > length ||
            rhs_items + rhs_length[rule] > MAX_RHS_ITEMS) return -1;

        int has_terminal = 0;
        for (int j = 0; j < rhs_length[rule]; ++j) {
            const int64_t symbol = input[offset++];
            if (symbol < 0 || symbol >= nonterminal_count + terminal_count) return -1;
            rhs[rhs_items++] = (int)symbol;
            if (symbol >= nonterminal_count) has_terminal = 1;
        }
        if (rhs_length[rule] > 0 && !has_terminal) {
            eligible[rule] = 1;
            remaining[rule] = rhs_length[rule];
        }
    }
    if (offset != length) return -1;

    int queue_tail = 0;
    for (int rule = 0; rule < rule_count; ++rule) {
        if (rhs_length[rule] == 0 && !nullable[lhs[rule]]) {
            nullable[lhs[rule]] = 1;
            queue[queue_tail++] = lhs[rule];
        }
    }

    int queue_head = 0;
    while (queue_head < queue_tail) {
        const int symbol = queue[queue_head++];
        for (int rule = 0; rule < rule_count; ++rule) {
            if (!eligible[rule]) continue;
            for (int j = 0; j < rhs_length[rule]; ++j) {
                if (rhs[rhs_start[rule] + j] == symbol) {
                    --remaining[rule];
                    if (remaining[rule] == 0 && !nullable[lhs[rule]]) {
                        nullable[lhs[rule]] = 1;
                        queue[queue_tail++] = lhs[rule];
                    }
                }
            }
        }
    }

    int64_t mask = 0;
    for (int symbol = 0; symbol < nonterminal_count; ++symbol)
        if (nullable[symbol]) mask |= INT64_C(1) << symbol;
    return mask;
}
