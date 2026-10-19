const min_runs = 1
const max_runs = 100
const element_count = 5000
const max_output_bytes = 700

struct TreeNode {
	value int
	left int
	right int
}

fn next_random(mut seed i64) int {
	seed = (seed * 1309 + 13849) & 65535
	return int(seed)
}

fn validate_tree(nodes []TreeNode, root int) bool {
	node := nodes[root]
	if node.left != -1 {
		child := nodes[node.left]
		if child.value <= node.value || !validate_tree(nodes, node.left) { return false }
	}
	if node.right != -1 {
		child := nodes[node.right]
		if child.value >= node.value || !validate_tree(nodes, node.right) { return false }
	}
	return true
}

fn build_and_check_pass(selected_run int) (int, bool) {
	mut values := [element_count]int{}
	mut nodes := [element_count]TreeNode{}
	mut seed := i64(74755)
	for index in 0 .. element_count {
		temp := next_random(mut seed)
		values[index] = temp - (temp / 100000) * 100000 - 50000
	}
	nodes[0] = TreeNode{value: values[0], left: -1, right: -1}
	mut used := 1
	for index in 1 .. element_count {
		mut current := 0
		for {
			if values[index] > nodes[current].value {
				if nodes[current].left == -1 {
					nodes[current].left = used
					nodes[used] = TreeNode{value: values[index], left: -1, right: -1}
					used++
					break
				}
				current = nodes[current].left
			} else if values[index] < nodes[current].value {
				if nodes[current].right == -1 {
					nodes[current].right = used
					nodes[used] = TreeNode{value: values[index], left: -1, right: -1}
					used++
					break
				}
				current = nodes[current].right
			} else {
				break
			}
		}
	}
	return values[selected_run + 1], validate_tree(nodes[..], 0)
}

fn append_text(mut buffer []u8, mut used int, text string) {
	for byte in text.bytes() {
		buffer[used] = byte
		used++
	}
}

fn append_integer(mut buffer []u8, mut used int, value int) {
	mut remaining := value
	if remaining < 0 {
		buffer[used] = u8(`-`)
		used++
		remaining = -remaining
	}
	mut reversed := [12]u8{}
	mut count := 0
	for {
		reversed[count] = u8(48 + remaining % 10)
		count++
		remaining /= 10
		if remaining == 0 { break }
	}
	for count > 0 {
		count--
		buffer[used] = reversed[count]
		used++
	}
}

@[export: 'stanford_treesort']
pub fn stanford_treesort(runs i64, mut output &u8, output_capacity usize) i64 {
	if runs < min_runs || runs > max_runs { return -1 }
	if unsafe { output == nil } { return -2 }

	mut staged := [max_output_bytes]u8{}
	mut used := 0
	for run in 0 .. int(runs) {
		value, valid := build_and_check_pass(run)
		append_integer(mut staged[..], mut used, value)
		append_text(mut staged[..], mut used, '\n')
		if !valid { append_text(mut staged[..], mut used, ' Error in Tree.\n') }
	}
	if output_capacity < usize(used) { return -2 }
	unsafe {
		for index in 0 .. used { output[index] = staged[index] }
	}
	return i64(used)
}
