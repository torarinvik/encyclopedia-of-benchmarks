module odd_even_jump_reachability_count

const max_n = 64
const max_parseable = 66

fn comes_before(input &i64, left int, right int, descending bool) bool {
	unsafe {
		left_value := input[left + 1]
		right_value := input[right + 1]
		if left_value != right_value { return if descending { left_value > right_value } else { left_value < right_value } }
		return left < right
	}
}

fn build_successors(input &i64, n int, descending bool, mut target [64]i64) {
	mut order := [64]int{}
	mut stack := [64]int{}
	for i in 0 .. n { order[i] = i; target[i] = -1 }
	for i in 1 .. n {
		key := order[i]
		mut position := i
		for position > 0 && comes_before(input, key, order[position - 1], descending) {
			order[position] = order[position - 1]
			position--
		}
		order[position] = key
	}
	mut stack_size := 0
	for i in 0 .. n {
		index := order[i]
		for stack_size > 0 && stack[stack_size - 1] < index {
			stack_size--
			target[stack[stack_size]] = i64(index)
		}
		stack[stack_size] = index
		stack_size++
	}
}

@[export: 'odd_even_jump_reachability_count']
pub fn odd_even_jump_reachability_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable { return -1 }
		if input[0] < 1 || input[0] > max_n { return -1 }
		n := int(input[0])
		if length != usize(n + 1) { return -1 }
		for i in 0 .. n { if input[i + 1] < -1000000 || input[i + 1] > 1000000 { return -1 } }
		mut odd_next := [64]i64{}
		mut even_next := [64]i64{}
		build_successors(input, n, false, mut odd_next)
		build_successors(input, n, true, mut even_next)
		mut odd := [64]bool{}
		mut even := [64]bool{}
		odd[n - 1] = true
		even[n - 1] = true
		mut i := n - 1
		for i > 0 {
			i--
			if odd_next[i] >= 0 { odd[i] = even[int(odd_next[i])] }
			if even_next[i] >= 0 { even[i] = odd[int(even_next[i])] }
		}
		mut count := i64(0)
		for i in 0 .. n { if odd[i] { count++ } }
		return count
	}
}
