package perfect_phylogeny_three_state_2sat

import "core:c"

MAX_TAXA :: 8
MAX_CHARACTERS :: 8
MAX_LITERALS :: 48
MAX_INPUT :: 67
Graph :: [MAX_LITERALS][MAX_LITERALS]bool

add_clause :: proc(graph: ^Graph, reverse: ^Graph, left, right: int) {
	from_left := left ^ 1
	from_right := right ^ 1
	graph[from_left][right] = true
	reverse[right][from_left] = true
	graph[from_right][left] = true
	reverse[left][from_right] = true
}

solve :: proc(values: [^]i64, length: int) -> i64 {
	if length < 2 || length > MAX_INPUT do return -1
	taxa_raw, characters_raw := values[0], values[1]
	if taxa_raw < 1 || taxa_raw > MAX_TAXA || characters_raw < 0 || characters_raw > MAX_CHARACTERS do return -1
	taxa, characters := int(taxa_raw), int(characters_raw)
	if length != 2 + taxa * characters do return -1

	masks: [MAX_CHARACTERS][3]u16
	for taxon := 0; taxon < taxa; taxon += 1 {
		for character := 0; character < characters; character += 1 {
			state := values[2 + taxon*characters + character]
			if state < 0 || state > 2 do return -1
			masks[character][int(state)] |= u16(1) << u32(taxon)
		}
	}

	graph, reverse: Graph
	for character := 0; character < characters; character += 1 {
		v0 := 3 * character
		add_clause(&graph, &reverse, 2*v0, 2*(v0+1))
		add_clause(&graph, &reverse, 2*v0, 2*(v0+2))
		add_clause(&graph, &reverse, 2*(v0+1), 2*(v0+2))
		present, missing := 0, 0
		for state := 0; state < 3; state += 1 {
			if masks[character][state] == 0 { missing = state } else { present += 1 }
		}
		if present == 2 {
			absent_literal := 2*(3*character+missing) + 1
			add_clause(&graph, &reverse, absent_literal, absent_literal)
		}
	}
	universe := (u16(1) << u32(taxa)) - 1
	for left_character := 0; left_character < characters; left_character += 1 {
		for right_character := left_character + 1; right_character < characters; right_character += 1 {
			for left_state := 0; left_state < 3; left_state += 1 {
				left := masks[left_character][left_state]
				for right_state := 0; right_state < 3; right_state += 1 {
					right := masks[right_character][right_state]
					if (left & right) != 0 && (left & universe & ~right) != 0 &&
						(right & universe & ~left) != 0 && (universe & ~(left | right)) != 0 {
						left_variable := 3*left_character + left_state
						right_variable := 3*right_character + right_state
						add_clause(&graph, &reverse, 2*left_variable+1, 2*right_variable+1)
					}
				}
			}
		}
	}

	literal_count := 6 * characters
	seen: [MAX_LITERALS]bool
	order, stack, next_index: [MAX_LITERALS]int
	order_count := 0
	for start := 0; start < literal_count; start += 1 {
		if seen[start] do continue
		top := 1
		stack[0] = start
		seen[start] = true
		for top > 0 {
			vertex := stack[top-1]
			next := next_index[vertex]
			for next < literal_count && (!graph[vertex][next] || seen[next]) { next += 1 }
			if next < literal_count {
				next_index[vertex] = next + 1
				seen[next] = true
				stack[top] = next
				top += 1
			} else {
				order[order_count] = vertex
				order_count += 1
				top -= 1
			}
		}
	}
	component: [MAX_LITERALS]int
	for i := 0; i < literal_count; i += 1 { component[i] = -1 }
	label := 0
	for order_count > 0 {
		order_count -= 1
		start := order[order_count]
		if component[start] >= 0 do continue
		top := 1
		stack[0] = start
		component[start] = label
		for top > 0 {
			top -= 1
			vertex := stack[top]
			for next := 0; next < literal_count; next += 1 {
				if reverse[vertex][next] && component[next] < 0 {
					component[next] = label
					stack[top] = next
					top += 1
				}
			}
		}
		label += 1
	}
	for variable := 0; variable < 3*characters; variable += 1 {
		if component[2*variable] == component[2*variable+1] do return 0
	}
	return 1
}

@(export)
perfect_phylogeny_three_state_2sat :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	return solve(input, int(length))
}
