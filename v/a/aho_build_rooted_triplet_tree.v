module aho_build_rooted_triplet_tree

const max_taxa = 7
const max_triplets = 105
const max_nodes = 13

fn store_word(output &u8, offset int, value i64) {
	for byte in 0 .. 8 { unsafe { output[offset + byte] = u8((value >> (8 * byte)) & 255) } }
}

@[export: 'aho_build_rooted_triplet_tree']
pub fn aho_build_rooted_triplet_tree(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 318 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_taxa || input[1] < 0 { return -1 }
		n := int(input[0])
		q_limit := n * (n - 1) * (n - 2) / 2
		if input[1] > i64(q_limit) { return -1 }
		q := int(input[1])
		if int(length) != 2 + 3 * q { return -1 }
		mut triples := [max_triplets * 3]int{}
		for i in 0 .. q {
			a0, b0, c0 := input[2 + 3 * i], input[3 + 3 * i], input[4 + 3 * i]
			if a0 < 0 || a0 >= i64(n) || b0 < 0 || b0 >= i64(n) || c0 < 0 || c0 >= i64(n) || a0 == b0 || a0 == c0 || b0 == c0 { return -1 }
			mut a := int(a0)
			mut b := int(b0)
			if a > b { a, b = b, a }
			for j in 0 .. i { if triples[3 * j] == a && triples[3 * j + 1] == b && triples[3 * j + 2] == int(c0) { return -1 } }
			triples[3 * i], triples[3 * i + 1], triples[3 * i + 2] = a, b, int(c0)
		}

		mut kind := [max_nodes]int{}
		mut node_value := [max_nodes]int{}
		mut tasks := [max_nodes]int{}
		mut top := 1
		tasks[0] = (1 << n) - 1
		mut node_count := 0
		mut compatible := true
		for top > 0 {
			top--
			mask := tasks[top]
			if (mask & (mask - 1)) == 0 {
				mut label := 0
				for (mask & (1 << label)) == 0 { label++ }
				kind[node_count], node_value[node_count] = 1, label
				node_count++
				continue
			}
			mut edge := [max_taxa * max_taxa]bool{}
			for i in 0 .. q {
				a, b, c := triples[3 * i], triples[3 * i + 1], triples[3 * i + 2]
				needed := (1 << a) | (1 << b) | (1 << c)
				if (mask & needed) == needed {
					edge[a * 7 + b] = true
					edge[b * 7 + a] = true
				}
			}
			mut seen := [max_taxa]bool{}
			mut components := [max_taxa]int{}
			mut component_count := 0
			for start in 0 .. n {
				if (mask & (1 << start)) == 0 || seen[start] { continue }
				mut queue := [max_taxa]int{}
				mut head := 0
				mut tail := 1
				mut component := 0
				queue[0], seen[start] = start, true
				for head < tail {
					current := queue[head]
					head++
					component |= 1 << current
					for other in 0 .. n {
						if edge[current * 7 + other] && !seen[other] { seen[other] = true; queue[tail] = other; tail++ }
					}
				}
				components[component_count] = component
				component_count++
			}
			if component_count == 1 { compatible = false; break }
			kind[node_count], node_value[node_count] = 0, component_count
			node_count++
			mut i := component_count
			for i > 0 { i--; tasks[top] = components[i]; top++ }
		}

		mut words := [max_nodes + 1]i64{}
		mut word_count := 1
		if compatible {
			words[0] = i64(node_count)
			for i in 0 .. node_count {
				if kind[i] == 1 { words[i + 1] = -i64(node_value[i] + 1) } else { words[i + 1] = i64(node_value[i]) }
			}
			word_count += node_count
		}
		bytes := word_count * 8
		if unsafe { output == nil } || output_capacity < usize(bytes) { return -2 }
		for i in 0 .. word_count { store_word(output, i * 8, words[i]) }
		return i64(bytes)
	}
}
