module maximum_employees_to_be_invited

const max_n = 8
const max_input = 10

@[export: 'maximum_employees_to_be_invited']
pub fn maximum_employees_to_be_invited(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	n_value := input[0]
	if n_value < 2 || n_value > max_n || length != usize(n_value + 1) { return -1 }
	n := int(n_value)
	mut favorite := []i64{len: max_n, init: 0}
	mut indegree := []i64{len: max_n, init: 0}
	mut chain := []i64{len: max_n, init: 1}
	mut queue := []int{len: max_n, init: 0}
	mut visited := []bool{len: max_n, init: false}
	for i in 0 .. n {
		target := input[i + 1]
		if target < 0 || target >= n_value || target == i64(i) { return -1 }
		favorite[i] = target
		indegree[int(target)]++
	}
	mut head, mut tail := 0, 0
	for i in 0 .. n {
		if indegree[i] == 0 { queue[tail] = i; tail++ }
	}
	for head < tail {
		node := queue[head]; head++
		target := int(favorite[node])
		chain[target] = max(chain[target], chain[node] + 1)
		indegree[target]--
		if indegree[target] == 0 { queue[tail] = target; tail++ }
	}
	mut pair_total := i64(0)
	mut longest_cycle := i64(0)
	for start in 0 .. n {
		if indegree[start] == 0 || visited[start] { continue }
		mut node, mut first, mut second := start, 0, 0
		mut cycle_length := 0
		for !visited[node] {
			visited[node] = true
			if cycle_length == 0 { first = node } else if cycle_length == 1 { second = node }
			cycle_length++
			node = int(favorite[node])
		}
		if cycle_length == 2 { pair_total += chain[first] + chain[second] }
		if i64(cycle_length) > longest_cycle { longest_cycle = i64(cycle_length) }
	}
	return max(pair_total, longest_cycle)
}
