module perfect_phylogeny_three_state_2sat

const max_taxa = 8
const max_characters = 8
const max_literals = 48
const max_input = 67

fn add_clause(mut graph [48][48]bool, mut reverse [48][48]bool, left int, right int) {
	from_left := left ^ 1
	from_right := right ^ 1
	graph[from_left][right] = true
	reverse[right][from_left] = true
	graph[from_right][left] = true
	reverse[left][from_right] = true
}

fn solve(values &i64, length usize) i64 {
	if length < 2 || length > max_input { return -1 }
	taxa_raw, characters_raw := values[0], values[1]
	if taxa_raw < 1 || taxa_raw > max_taxa || characters_raw < 0 || characters_raw > max_characters { return -1 }
	taxa, characters := int(taxa_raw), int(characters_raw)
	if length != usize(2 + taxa * characters) { return -1 }
	mut masks := [24]u16{}
	for taxon in 0 .. taxa {
		for character in 0 .. characters {
			state := values[2 + taxon * characters + character]
			if state < 0 || state > 2 { return -1 }
			masks[3 * character + int(state)] |= u16(1) << u16(taxon)
		}
	}
	mut graph := [48][48]bool{}
	mut reverse := [48][48]bool{}
	for character in 0 .. characters {
		v0 := 3 * character
		add_clause(mut graph, mut reverse, 2 * v0, 2 * (v0 + 1))
		add_clause(mut graph, mut reverse, 2 * v0, 2 * (v0 + 2))
		add_clause(mut graph, mut reverse, 2 * (v0 + 1), 2 * (v0 + 2))
		mut present := 0
		mut missing := 0
		for state in 0 .. 3 {
			if masks[3 * character + state] == 0 { missing = state } else { present++ }
		}
		if present == 2 {
			absent_literal := 2 * (3 * character + missing) + 1
			add_clause(mut graph, mut reverse, absent_literal, absent_literal)
		}
	}
	universe := (u16(1) << u16(taxa)) - 1
	for left_character in 0 .. characters {
		for right_character in left_character + 1 .. characters {
			for left_state in 0 .. 3 {
				left := masks[3 * left_character + left_state]
				for right_state in 0 .. 3 {
					right := masks[3 * right_character + right_state]
					if (left & right) != 0 && (left & universe & ~right) != 0 && (right & universe & ~left) != 0 && (universe & ~(left | right)) != 0 {
						left_variable := 3 * left_character + left_state
						right_variable := 3 * right_character + right_state
						add_clause(mut graph, mut reverse, 2 * left_variable + 1, 2 * right_variable + 1)
					}
				}
			}
		}
	}
	literal_count := 6 * characters
	mut seen := [48]bool{}
	mut order := [48]int{}
	mut stack := [48]int{}
	mut next_index := [48]int{}
	mut order_count := 0
	for start in 0 .. literal_count {
		if seen[start] { continue }
		mut top := 1
		stack[0] = start
		seen[start] = true
		for top > 0 {
			vertex := stack[top - 1]
			mut next := next_index[vertex]
			for next < literal_count && (!graph[vertex][next] || seen[next]) { next++ }
			if next < literal_count {
				next_index[vertex] = next + 1
				seen[next] = true
				stack[top] = next
				top++
			} else {
				order[order_count] = vertex
				order_count++
				top--
			}
		}
	}
	mut component := [48]int{}
	for i in 0 .. literal_count { component[i] = -1 }
	mut label := 0
	for order_count > 0 {
		order_count--
		start := order[order_count]
		if component[start] >= 0 { continue }
		mut top := 1
		stack[0] = start
		component[start] = label
		for top > 0 {
			top--
			vertex := stack[top]
			for next in 0 .. literal_count {
				if reverse[vertex][next] && component[next] < 0 {
					component[next] = label
					stack[top] = next
					top++
				}
			}
		}
		label++
	}
	for variable in 0 .. 3 * characters {
		if component[2 * variable] == component[2 * variable + 1] { return 0 }
	}
	return 1
}

@[export: 'perfect_phylogeny_three_state_2sat']
pub fn perfect_phylogeny_three_state_2sat(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input { return -1 }
		return solve(input, length)
	}
}
