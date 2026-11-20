package aho_build_rooted_triplet_tree

import "core:c"

MAX_TAXA :: 7
MAX_TRIPLETS :: 105
MAX_NODES :: 13

store_word :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> u64(8*byte)) & 255) }
}

@(export)
aho_build_rooted_triplet_tree :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 318 do return -1
	if input[0] < 1 || input[0] > MAX_TAXA || input[1] < 0 do return -1
	n := int(input[0])
	q_limit := n * (n-1) * (n-2) / 2
	if input[1] > i64(q_limit) do return -1
	q := int(input[1])
	if int(length) != 2 + 3*q do return -1

	triples: [MAX_TRIPLETS][3]int
	for i := 0; i < q; i += 1 {
		a0, b0, c0 := input[2+3*i], input[3+3*i], input[4+3*i]
		if a0 < 0 || a0 >= i64(n) || b0 < 0 || b0 >= i64(n) || c0 < 0 || c0 >= i64(n) || a0 == b0 || a0 == c0 || b0 == c0 do return -1
		a, b := int(a0), int(b0)
		if a > b { a, b = b, a }
		for j := 0; j < i; j += 1 { if triples[j][0] == a && triples[j][1] == b && triples[j][2] == int(c0) do return -1 }
		triples[i] = {a, b, int(c0)}
	}

	kind: [MAX_NODES]int
	node_value: [MAX_NODES]int
	tasks: [MAX_NODES]int
	top := 1
	tasks[0] = (1 << n) - 1
	node_count := 0
	compatible := true
	for top > 0 {
		top -= 1
		mask := tasks[top]
		if (mask & (mask-1)) == 0 {
			label := 0
			for (mask & (1 << label)) == 0 { label += 1 }
			kind[node_count] = 1; node_value[node_count] = label; node_count += 1
			continue
		}
		edge: [MAX_TAXA][MAX_TAXA]bool
		for i := 0; i < q; i += 1 {
			a, b, c := triples[i][0], triples[i][1], triples[i][2]
			needed := (1 << a) | (1 << b) | (1 << c)
			if (mask & needed) == needed { edge[a][b] = true; edge[b][a] = true }
		}
		seen: [MAX_TAXA]bool
		components: [MAX_TAXA]int
		component_count := 0
		for start := 0; start < n; start += 1 {
			if (mask & (1 << start)) == 0 || seen[start] do continue
			queue: [MAX_TAXA]int
			head, tail := 0, 1
			queue[0] = start
			seen[start] = true
			component := 0
			for head < tail {
				current := queue[head]; head += 1
				component |= 1 << current
				for other := 0; other < n; other += 1 {
					if edge[current][other] && !seen[other] { seen[other] = true; queue[tail] = other; tail += 1 }
				}
			}
			components[component_count] = component; component_count += 1
		}
		if component_count == 1 { compatible = false; break }
		kind[node_count] = 0; node_value[node_count] = component_count; node_count += 1
		for i := component_count; i > 0; i -= 1 { tasks[top] = components[i-1]; top += 1 }
	}

	words: [MAX_NODES+1]i64
	word_count := 1
	if compatible {
		words[0] = i64(node_count)
		for i := 0; i < node_count; i += 1 {
			if kind[i] == 1 { words[i+1] = -i64(node_value[i]+1) } else { words[i+1] = i64(node_value[i]) }
		}
		word_count += node_count
	} else { words[0] = 0 }
	bytes := word_count * 8
	if output == nil || int(output_capacity) < bytes do return -2
	for i := 0; i < word_count; i += 1 { store_word(output, i*8, words[i]) }
	return i64(bytes)
}
