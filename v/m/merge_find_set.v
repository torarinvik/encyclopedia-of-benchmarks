module merge_find_set

const max_n = 256
const max_merges = 512
const max_parseable_input_length = 1028

fn find_root(parent []int, mut element int) int {
	for parent[element] != element { element = parent[element] }
	return element
}

@[export: 'merge_find_set']
pub fn merge_find_set(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > usize(max_parseable_input_length) { return -1 }
	unsafe {
		n_value, merge_count_value := input[0], input[1]
		if n_value < 1 || n_value > max_n || merge_count_value < 0 || merge_count_value > max_merges { return -1 }
		n, merge_count := int(n_value), int(merge_count_value)
		if length != usize(2 * merge_count + 3) { return -1 }
		mut parent := [max_n]int{}
		mut rank := [max_n]int{}
		for element in 0 .. n { parent[element] = element }
		for merge_index in 0 .. merge_count {
			position := 2 + 2 * merge_index
			first_value, second_value := input[position], input[position + 1]
			if first_value < 0 || first_value >= n_value || second_value < 0 || second_value >= n_value { return -1 }
			first_root := find_root(parent[..], int(first_value))
			second_root := find_root(parent[..], int(second_value))
			if first_root == second_root { continue }
			if rank[first_root] < rank[second_root] { parent[first_root] = second_root
			} else if rank[first_root] > rank[second_root] { parent[second_root] = first_root
			} else { parent[first_root] = second_root; rank[second_root]++ }
		}
		query := input[2 + 2 * merge_count]
		if query < 0 || query >= n_value { return -1 }
		return i64(find_root(parent[..], int(query)))
	}
}
