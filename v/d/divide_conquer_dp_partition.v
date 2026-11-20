module divide_conquer_dp_partition

const max_n = 64
const max_groups = 8
const max_input = 66
const stack_capacity = 136
const inf = i64(0x1fffffffffffffff)

struct DcdpTask {
	left int
	right int
	low int
	high int
}

fn compute_row(previous []i64, mut current []i64, prefix []i64, n int, group int) {
	mut stack := []DcdpTask{len: stack_capacity}
	mut top := 1
	stack[0] = DcdpTask{left: group, right: n, low: group - 1, high: n - 1}
	for top > 0 {
		top--
		task := stack[top]
		if task.left > task.right { continue }
		middle := task.left + (task.right - task.left) / 2
		upper := if task.high < middle - 1 { task.high } else { middle - 1 }
		mut best := inf
		mut best_split := task.low
		for split := task.low; split <= upper; split++ {
			if previous[split] == inf { continue }
			segment := prefix[middle] - prefix[split]
			candidate := previous[split] + segment * segment
			if candidate < best { best = candidate; best_split = split }
		}
		current[middle] = best
		if middle < task.right {
			stack[top] = DcdpTask{left: middle + 1, right: task.right, low: best_split, high: task.high}
			top++
		}
		if task.left < middle {
			stack[top] = DcdpTask{left: task.left, right: middle - 1, low: task.low, high: best_split}
			top++
		}
	}
}

@[export: 'divide_conquer_dp_partition']
pub fn divide_conquer_dp_partition(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 3 || length > max_input { return -1 }
		n_value := values[0]
		groups_value := values[1]
		if n_value < 1 || n_value > max_n || groups_value < 1 || groups_value > max_groups ||
			groups_value > n_value || length != usize(n_value + 2) { return -1 }
		n := int(n_value)
		groups := int(groups_value)
		mut prefix := []i64{len: max_n + 1}
		mut first := []i64{len: max_n + 1, init: inf}
		mut second := []i64{len: max_n + 1, init: inf}
		for i in 0 .. n {
			value := values[i + 2]
			if value < 0 || value > 1000 { return -1 }
			prefix[i + 1] = prefix[i] + value
		}
		first[0] = 0
		mut previous := first
		mut current := second
		for group in 1 .. groups + 1 {
			for i in 0 .. n + 1 { current[i] = inf }
			compute_row(previous, mut current, prefix, n, group)
			temporary := previous
			previous = current
			current = temporary
		}
		return previous[n]
	}
}
