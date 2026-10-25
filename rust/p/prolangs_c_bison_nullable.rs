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
const MAX_NONTERMINALS: usize = 16;
const MAX_TERMINALS: usize = 16;
const MAX_RULES: usize = 32;
const MAX_RHS: usize = 8;
const MAX_RHS_ITEMS: usize = MAX_RULES * MAX_RHS;
const MAX_INPUT_LENGTH: usize = 3 + MAX_RULES * (2 + MAX_RHS);

#[no_mangle]
pub unsafe extern "C" fn prolangs_c_bison_nullable(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return -1; }
    let values = std::slice::from_raw_parts(input, length);
    if values[0] < 1 || values[0] > MAX_NONTERMINALS as i64 ||
        values[1] < 0 || values[1] > MAX_TERMINALS as i64 ||
        values[2] < 1 || values[2] > MAX_RULES as i64 { return -1; }
    let nonterminal_count = values[0] as usize;
    let terminal_count = values[1] as usize;
    let rule_count = values[2] as usize;
    let mut lhs = [0usize; MAX_RULES];
    let mut rhs_start = [0usize; MAX_RULES];
    let mut rhs_length = [0usize; MAX_RULES];
    let mut remaining = [0usize; MAX_RULES];
    let mut rhs = [0usize; MAX_RHS_ITEMS];
    let mut eligible = [false; MAX_RULES];
    let mut nullable = [false; MAX_NONTERMINALS];
    let mut queue = [0usize; MAX_NONTERMINALS];
    let mut rhs_items = 0usize;
    let mut offset = 3usize;

    for rule in 0..rule_count {
        if offset + 2 > length { return -1; }
        if values[offset] < 0 || values[offset] >= nonterminal_count as i64 ||
            values[offset + 1] < 0 || values[offset + 1] > MAX_RHS as i64 { return -1; }
        lhs[rule] = values[offset] as usize;
        rhs_length[rule] = values[offset + 1] as usize;
        offset += 2;
        rhs_start[rule] = rhs_items;
        if offset + rhs_length[rule] > length || rhs_items + rhs_length[rule] > MAX_RHS_ITEMS { return -1; }
        let mut has_terminal = false;
        for _ in 0..rhs_length[rule] {
            let symbol = values[offset];
            offset += 1;
            if symbol < 0 || symbol >= (nonterminal_count + terminal_count) as i64 { return -1; }
            rhs[rhs_items] = symbol as usize;
            rhs_items += 1;
            if symbol as usize >= nonterminal_count { has_terminal = true; }
        }
        if rhs_length[rule] > 0 && !has_terminal {
            eligible[rule] = true;
            remaining[rule] = rhs_length[rule];
        }
    }
    if offset != length { return -1; }

    let mut queue_tail = 0usize;
    for rule in 0..rule_count {
        if rhs_length[rule] == 0 && !nullable[lhs[rule]] {
            nullable[lhs[rule]] = true;
            queue[queue_tail] = lhs[rule];
            queue_tail += 1;
        }
    }
    let mut queue_head = 0usize;
    while queue_head < queue_tail {
        let symbol = queue[queue_head];
        queue_head += 1;
        for rule in 0..rule_count {
            if !eligible[rule] { continue; }
            for j in 0..rhs_length[rule] {
                if rhs[rhs_start[rule] + j] == symbol {
                    remaining[rule] -= 1;
                    if remaining[rule] == 0 && !nullable[lhs[rule]] {
                        nullable[lhs[rule]] = true;
                        queue[queue_tail] = lhs[rule];
                        queue_tail += 1;
                    }
                }
            }
        }
    }
    let mut mask = 0i64;
    for symbol in 0..nonterminal_count {
        if nullable[symbol] { mask |= 1i64 << symbol; }
    }
    mask
}
