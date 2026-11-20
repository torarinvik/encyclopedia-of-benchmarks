package online_bipartiteness_dsu

import "core:c"

MAX_N :: 32
MAX_Q :: 64
MAX_INPUT_VALUES :: 195

find_parity :: proc "contextless" (parent, parity: [^]i64, start: int, xor_to_root: ^i64) -> int {
	root := start
	total := i64(0)
	for int(parent[root]) != root { total ^= parity[root]; root = int(parent[root]) }
	node, accumulated := start, i64(0)
	for int(parent[node]) != node {
		next := int(parent[node])
		edge := parity[node]
		parent[node] = i64(root)
		parity[node] = total ^ accumulated
		accumulated ^= edge
		node = next
	}
	xor_to_root^ = total
	return root
}

@(export)
online_bipartiteness_dsu :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if length != c.size_t(2 + 3*q) do return -1
	for j := 0; j < q; j += 1 {
		opcode, a, b := input[2+3*j], input[3+3*j], input[4+3*j]
		if opcode == 0 {
			if a < 0 || a >= n_value || b < 0 || b >= n_value do return -1
		} else if opcode == 1 {
			if a < 0 || a >= n_value || b != 0 do return -1
		} else { return -1 }
	}
	parent: [MAX_N]i64
	size: [MAX_N]i64
	parity: [MAX_N]i64
	bad: [MAX_N]i64
	for i := 0; i < n; i += 1 { parent[i] = i64(i); size[i] = 1 }
	checksum, query_ordinal := i64(0), i64(0)
	for j := 0; j < q; j += 1 {
		opcode := input[2+3*j]
		a := int(input[3+3*j])
		if opcode == 1 {
			ignored := i64(0)
			root := find_parity(&parent[0], &parity[0], a, &ignored)
			answer := i64(1)
			if bad[root] != 0 { answer = 0 }
			checksum += (query_ordinal+1) * (answer+1)
			query_ordinal += 1
			continue
		}
		b := int(input[4+3*j])
		parity_a, parity_b := i64(0), i64(0)
		root_a := find_parity(&parent[0], &parity[0], a, &parity_a)
		root_b := find_parity(&parent[0], &parity[0], b, &parity_b)
		if root_a == root_b {
			if parity_a == parity_b { bad[root_a] = 1 }
			continue
		}
		if size[root_a] < size[root_b] {
			root_a, root_b = root_b, root_a
			parity_a, parity_b = parity_b, parity_a
		}
		parent[root_b] = i64(root_a)
		parity[root_b] = parity_a ^ parity_b ^ 1
		size[root_a] += size[root_b]
		if bad[root_b] != 0 { bad[root_a] = 1 }
	}
	return checksum
}
