const max_n = i64(64)
const encoding_base = i64(65)

@[export: 'functional_graph_cycle_parameters']
pub fn functional_graph_cycle_parameters(input &i64, length usize) i64 {
	if length < 3 || length > 66 { return -1 }
	unsafe {
		if input == nil { return -1 }
		n, start := input[0], input[1]
		if n < 1 || n > max_n || start < 0 || start >= n || length != usize(n + 2) { return -1 }
		for i in 0 .. int(n) {
			successor := input[2 + i]
			if successor < 0 || successor >= n { return -1 }
		}
		tortoise := input[2 + int(start)]
		hare := input[2 + int(input[2 + int(start)])]
		for tortoise != hare {
			tortoise = input[2 + int(tortoise)]
			hare = input[2 + int(input[2 + int(hare)])]
		}
		mu := i64(0)
		tortoise = start
		for tortoise != hare {
			tortoise = input[2 + int(tortoise)]
			hare = input[2 + int(hare)]
			mu++
		}
		lambda := i64(1)
		hare = input[2 + int(tortoise)]
		for hare != tortoise {
			hare = input[2 + int(hare)]
			lambda++
		}
		return encoding_base * mu + lambda
	}
}
