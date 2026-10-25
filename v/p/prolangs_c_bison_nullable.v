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
module prolangs_c_bison_nullable

const max_nonterminals = 16
const max_terminals = 16
const max_rules = 32
const max_rhs = 8
const max_rhs_items = max_rules * max_rhs
const max_input_length = 3 + max_rules * (2 + max_rhs)

@[export: 'prolangs_c_bison_nullable']
pub fn prolangs_c_bison_nullable(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_nonterminals || input[1] < 0 || input[1] > max_terminals ||
			input[2] < 1 || input[2] > max_rules { return -1 }
		nonterminal_count := int(input[0])
		terminal_count := int(input[1])
		rule_count := int(input[2])
		mut lhs := [max_rules]int{}
		mut rhs_start := [max_rules]int{}
		mut rhs_length := [max_rules]int{}
		mut remaining := [max_rules]int{}
		mut rhs := [max_rhs_items]int{}
		mut eligible := [max_rules]bool{}
		mut nullable := [max_nonterminals]bool{}
		mut symbol_queue := [max_nonterminals]int{}
		mut rhs_items := 0
		mut offset := 3
		for rule in 0 .. rule_count {
			if offset + 2 > int(length) { return -1 }
			if input[offset] < 0 || input[offset] >= i64(nonterminal_count) ||
				input[offset + 1] < 0 || input[offset + 1] > max_rhs { return -1 }
			lhs[rule] = int(input[offset])
			rhs_length[rule] = int(input[offset + 1])
			offset += 2
			rhs_start[rule] = rhs_items
			if offset + rhs_length[rule] > int(length) || rhs_items + rhs_length[rule] > max_rhs_items { return -1 }
			mut has_terminal := false
			for _ in 0 .. rhs_length[rule] {
				symbol := input[offset]
				offset++
				if symbol < 0 || symbol >= i64(nonterminal_count + terminal_count) { return -1 }
				rhs[rhs_items] = int(symbol)
				rhs_items++
				if symbol >= i64(nonterminal_count) { has_terminal = true }
			}
			if rhs_length[rule] > 0 && !has_terminal {
				eligible[rule] = true
				remaining[rule] = rhs_length[rule]
			}
		}
		if offset != int(length) { return -1 }

		mut queue_tail := 0
		for rule in 0 .. rule_count {
			if rhs_length[rule] == 0 && !nullable[lhs[rule]] {
				nullable[lhs[rule]] = true
				symbol_queue[queue_tail] = lhs[rule]
				queue_tail++
			}
		}
		mut queue_head := 0
		for queue_head < queue_tail {
			symbol := symbol_queue[queue_head]
			queue_head++
			for rule in 0 .. rule_count {
				if !eligible[rule] { continue }
				for j in 0 .. rhs_length[rule] {
					if rhs[rhs_start[rule] + j] == symbol {
						remaining[rule]--
						if remaining[rule] == 0 && !nullable[lhs[rule]] {
							nullable[lhs[rule]] = true
							symbol_queue[queue_tail] = lhs[rule]
							queue_tail++
						}
					}
				}
			}
		}
		mut mask := i64(0)
		mut bit := i64(1)
		for symbol in 0 .. nonterminal_count {
			if nullable[symbol] { mask += bit }
			bit *= 2
		}
		return mask
	}
}
