package merge_find_set

import "core:c"

MAX_N :: 256
MAX_MERGES :: 512
MAX_VALID_INPUT_LENGTH :: c.size_t(1027)
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(1028)

find_root :: proc "contextless" (parent: [^]int, element: int) -> int {
	root := element
	for parent[root] != root { root = parent[root] }
	return root
}

merge_find_set :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	n_value, merge_count_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || merge_count_value < 0 || merge_count_value > MAX_MERGES do return -1
	n, merge_count := int(n_value), int(merge_count_value)
	if length != c.size_t(2*merge_count+3) || length > MAX_VALID_INPUT_LENGTH do return -1
	var parent: [MAX_N]int
	var rank: [MAX_N]int
	for element in 0 ..< n { parent[element] = element }
	for merge_index in 0 ..< merge_count {
		position := 2 + 2*merge_index
		first_value, second_value := input[position], input[position+1]
		if first_value < 0 || first_value >= n_value || second_value < 0 || second_value >= n_value do return -1
		first_root := find_root(&parent[0], int(first_value))
		second_root := find_root(&parent[0], int(second_value))
		if first_root == second_root { continue }
		if rank[first_root] < rank[second_root] { parent[first_root] = second_root
		} else if rank[first_root] > rank[second_root] { parent[second_root] = first_root
		} else { parent[first_root] = second_root; rank[second_root] += 1 }
	}
	query := input[2+2*merge_count]
	if query < 0 || query >= n_value do return -1
	return i64(find_root(&parent[0], int(query)))
}
