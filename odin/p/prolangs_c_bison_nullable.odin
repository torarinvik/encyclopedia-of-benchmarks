// Part of the Bison parser generator,
// Copyright (C) 1984 Bob Corbett and Free Software Foundation, Inc.
//
// BISON is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY. No author or distributor accepts responsibility to anyone
// for the consequences of using it or for whether it serves any
// particular purpose or works at all, unless he says so in writing.
// Refer to the BISON General Public License for full details.
//
// Everyone is granted permission to copy, modify and redistribute BISON,
// but only under the conditions described in the BISON General Public
// License. A copy of this license is supposed to have been given to you
// along with BISON so you can know your rights and responsibilities. It
// should be in a file named COPYING. Among other things, the copyright
// notice and this notice must be preserved on all copies.
//
// In other words, you are welcome to use, share and improve this program.
// You are forbidden to forbid anyone else to use, share and improve
// what you give them. Help stamp out software-hoarding!
//
// Modified 2026: bounded numeric grammar adapter; no upstream code is copied.
package prolangs_c_bison_nullable

import "core:c"

MAX_NONTERMINALS :: 16
MAX_TERMINALS :: 16
MAX_RULES :: 32
MAX_RHS :: 8
MAX_RHS_ITEMS :: MAX_RULES * MAX_RHS
MAX_INPUT_LENGTH :: 3 + MAX_RULES * (2 + MAX_RHS)

@(export)
prolangs_c_bison_nullable :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 5 || length > MAX_INPUT_LENGTH do return -1
    if input[0] < 1 || input[0] > MAX_NONTERMINALS ||
        input[1] < 0 || input[1] > MAX_TERMINALS ||
        input[2] < 1 || input[2] > MAX_RULES do return -1
    nonterminal_count := int(input[0])
    terminal_count := int(input[1])
    rule_count := int(input[2])
    lhs, rhs_start, rhs_length, remaining: [MAX_RULES]int = {}
    rhs: [MAX_RHS_ITEMS]int = {}
    eligible: [MAX_RULES]bool = {}
    nullable: [MAX_NONTERMINALS]bool = {}
    symbol_queue: [MAX_NONTERMINALS]int = {}
    rhs_items := 0
    offset := 3

    for rule := 0; rule < rule_count; rule += 1 {
        if offset + 2 > int(length) do return -1
        if input[offset] < 0 || input[offset] >= i64(nonterminal_count) ||
            input[offset+1] < 0 || input[offset+1] > MAX_RHS do return -1
        lhs[rule] = int(input[offset])
        rhs_length[rule] = int(input[offset+1])
        offset += 2
        rhs_start[rule] = rhs_items
        if offset + rhs_length[rule] > int(length) || rhs_items + rhs_length[rule] > MAX_RHS_ITEMS do return -1
        has_terminal := false
        for j := 0; j < rhs_length[rule]; j += 1 {
            symbol := input[offset]
            offset += 1
            if symbol < 0 || symbol >= i64(nonterminal_count+terminal_count) do return -1
            rhs[rhs_items] = int(symbol)
            rhs_items += 1
            if symbol >= i64(nonterminal_count) do has_terminal = true
        }
        if rhs_length[rule] > 0 && !has_terminal {
            eligible[rule] = true
            remaining[rule] = rhs_length[rule]
        }
    }
    if offset != int(length) do return -1

    queue_tail := 0
    for rule := 0; rule < rule_count; rule += 1 {
        if rhs_length[rule] == 0 && !nullable[lhs[rule]] {
            nullable[lhs[rule]] = true
            symbol_queue[queue_tail] = lhs[rule]
            queue_tail += 1
        }
    }
    queue_head := 0
    for queue_head < queue_tail {
        symbol := symbol_queue[queue_head]
        queue_head += 1
        for rule := 0; rule < rule_count; rule += 1 {
            if !eligible[rule] do continue
            for j := 0; j < rhs_length[rule]; j += 1 {
                if rhs[rhs_start[rule]+j] == symbol {
                    remaining[rule] -= 1
                    if remaining[rule] == 0 && !nullable[lhs[rule]] {
                        nullable[lhs[rule]] = true
                        symbol_queue[queue_tail] = lhs[rule]
                        queue_tail += 1
                    }
                }
            }
        }
    }
    mask: i64 = 0
    bit: i64 = 1
    for symbol := 0; symbol < nonterminal_count; symbol += 1 {
        if nullable[symbol] do mask += bit
        bit *= 2
    }
    return mask
}
